-- Queue artwork manager - handles multiple small album covers for queue display
local kitty = require("vinyl.kitty")
local cache = require("vinyl.cache")

local M = {}

-- Initialize cache directory
cache.init()

-- Cache of loaded images by album name
-- Structure: { [album_name] = { image, temp_file } }
M.cache = {}

-- Track which albums are currently being loaded to avoid duplicates
M.loading = {}

-- Current buffer reference
M.current_buf = nil

-- Counter for unique image IDs (starts at 2000000 to avoid collision with main artwork)
M.image_id_counter = 2000000

-- Clear all queue artwork (called on UI close)
-- Note: We DON'T clear the cache on track changes - keep it for reuse!
function M.clear()
	for album_name, data in pairs(M.cache) do
		if data.image then
			kitty.delete_image(data.image, M.current_buf)
		end
		-- NOTE: We do NOT delete cached files - they're persistent!
	end

	M.cache = {}
	M.loading = {}

	-- Force redraw
	vim.schedule(function()
		vim.cmd("redraw!")
	end)
end

-- Load and display artwork for a specific album
-- album_name: The album name to fetch artwork for
-- buf: Buffer to display in
-- row: Row position (1-indexed for display_image)
-- col: Column position (0-indexed)
-- artwork_data: Optional artwork data { url = "..." } for Spotify or { path = "..." } for Apple Music
-- callback: Called with (success) when complete
function M.display_album_artwork(album_name, buf, row, col, artwork_data, callback)
	M.current_buf = buf

	-- Check Kitty memory cache first (already loaded)
	if M.cache[album_name] then
		local data = M.cache[album_name]
		if data.image then
			-- Use cached image, just reposition it (4x2 cells - 4 wide, 2 tall)
			kitty.display_image(data.image, row, col, 4, 2, buf)
			if callback then
				callback(true)
			end
			return
		end
	end

	-- Check persistent file cache
	-- Use "any" to prefer main (high-res) but fallback to thumbnail if that's all we have
	-- This allows queue to reuse high-quality main artwork when available
	local has_cached, cached_path = cache.has_cached_artwork(album_name, "any")
	if has_cached then
		-- Load from persistent cache (much faster than fetching!)
		M.load_from_file(album_name, cached_path, buf, row, col, callback)
		return
	end

	-- Check if already loading this album
	if M.loading[album_name] then
		if callback then
			callback(false)
		end
		return
	end

	-- Mark as loading
	M.loading[album_name] = true

	-- If artwork_data was provided (from queue with URLs), use it directly
	if artwork_data then
		M.fetch_and_cache_artwork(artwork_data, album_name, buf, row, col, callback)
		return
	end

	-- Otherwise, fetch artwork from Apple Music backend for this album
	local backend_module = require("vinyl")
	local backend = backend_module.get_backend()

	if not backend or not backend.get_album_artwork_async then
		M.loading[album_name] = nil
		if callback then
			callback(false)
		end
		return
	end

	backend.get_album_artwork_async(album_name, function(artwork, err)
		M.loading[album_name] = nil

		if err or not artwork then
			if callback then
				callback(false)
			end
			return
		end

		M.fetch_and_cache_artwork(artwork, album_name, buf, row, col, callback)
	end)
end

-- Fetch artwork from URL or file path and cache it (for queue thumbnails)
-- Similar to main artwork.lua but for 4x2 thumbnails
function M.fetch_and_cache_artwork(artwork, album_name, buf, row, col, callback)
	-- Use "thumbnail" size hint for low-res queue artwork
	-- This prevents polluting the main cache with low-quality images
	local png_path = cache.get_album_cache_path(album_name, "png", "thumbnail")

	-- Handle URL-based artwork (Spotify) vs file-based (Apple Music)
	if artwork.url then
		-- Download to temp file first
		local temp_path = cache.get_album_cache_path(album_name, "tmp", "thumbnail")
		local curl_cmd = string.format('curl -s -L -w "\\n%%{content_type}" -o "%s" "%s"', temp_path, artwork.url)

		local output = vim.fn.system(curl_cmd)
		if vim.v.shell_error ~= 0 then
			M.loading[album_name] = nil
			if callback then
				callback(false)
			end
			return
		end

		-- Extract content-type from output
		local content_type = output:match("\n([^\n]+)$")

		-- Check if it's an image format we can handle
		if content_type and content_type:match("video") then
			M.loading[album_name] = nil
			if callback then
				callback(false)
			end
			return
		end

		-- Convert to PNG
		local convert_result = vim.fn.system(string.format('convert "%s" "%s" 2>&1', temp_path, png_path))
		if vim.v.shell_error ~= 0 then
			M.loading[album_name] = nil
			if callback then
				callback(false)
			end
			return
		end

		-- Clean up temp file
		vim.fn.delete(temp_path)
	elseif artwork.path then
		-- File-based artwork (Apple Music)
		local convert_result = vim.fn.system(string.format('convert "%s" "%s"', artwork.path, png_path))
		if vim.v.shell_error ~= 0 then
			M.loading[album_name] = nil
			if callback then
				callback(false)
			end
			return
		end
	else
		M.loading[album_name] = nil
		if callback then
			callback(false)
		end
		return
	end

	-- Verify PNG is valid
	local verify_result = vim.fn.system(string.format('file "%s"', png_path))
	if not verify_result:match("PNG image data") then
		M.loading[album_name] = nil
		if callback then
			callback(false)
		end
		return
	end

	-- Load into Kitty and cache
	M.load_from_file(album_name, png_path, buf, row, col, callback)
	M.loading[album_name] = nil
end

-- Load artwork from a file into Kitty and cache it
-- Helper function used by both cache hits and new downloads
function M.load_from_file(album_name, png_path, buf, row, col, callback)
	-- Load image into Kitty with unique ID from counter
	M.image_id_counter = M.image_id_counter + 1
	local img, load_err = kitty.load_image(png_path, {
		id = M.image_id_counter,
	})

	if not img then
		if callback then
			callback(false)
		end
		return
	end

	-- Cache the image in memory
	M.cache[album_name] = {
		image = img,
		cache_file = png_path, -- Reference to persistent cache file
	}

	-- Display at the specified position (4x2 cells - 4 wide, 2 tall)
	kitty.display_image(img, row, col, 4, 2, buf)

	if callback then
		callback(true)
	end

	-- Force redraw
	vim.schedule(function()
		vim.cmd("redraw")
	end)
end

-- Display artwork for all tracks in a queue (not currently used - we display individually)
-- queue: Queue data structure with upcoming_tracks[] containing {name, artist, album}
-- buf: Buffer to display in
-- start_row: Starting row for first track artwork
-- row_spacing: Number of rows between each track (should match UI spacing)
function M.display_queue_artworks(queue, buf, start_row, row_spacing)
	if not queue or not queue.upcoming_tracks then
		return
	end

	M.current_buf = buf

	-- Display artwork for each track
	local row = start_row
	for i, track in ipairs(queue.upcoming_tracks) do
		if track.album and track.album ~= "" then
			-- Display 4x2 artwork at column 2 (leaving 2 column margin on left)
			M.display_album_artwork(track.album, buf, row, 2, nil)
		end

		-- Move to next track position
		row = row + row_spacing
	end
end

return M
