local player = require("vinyl.player")
local config = require("vinyl.config")
local kitty = require("vinyl.kitty")
local cache = require("vinyl.cache")

local M = {}

-- Album-based cache: { [album_name] = { image, cache_file } }
M.album_cache = {}

M.current_image = nil
M.current_album = nil -- Track by album instead of track_id
M.is_loading = false
M.current_buf = nil

-- Counter for unique image IDs (starts at 1000000, separate from queue artwork)
M.image_id_counter = 1000000

-- Initialize cache directory
cache.init()

-- Clear currently displayed artwork (but keep cache)
function M.clear()
	-- Delete the currently displayed image from screen (but keep in cache for quick reload)
	if M.current_image and M.current_buf then
		kitty.delete_image(M.current_image, M.current_buf)
	end

	M.current_image = nil
	M.current_album = nil
	M.is_loading = false

	-- Force a redraw to ensure terminal updates
	vim.schedule(function()
		vim.cmd("redraw!")
	end)
end

-- Clear all cached artwork (called on UI close)
function M.clear_all()
	for album_name, data in pairs(M.album_cache) do
		if data.image then
			kitty.delete_image(data.image, M.current_buf)
		end
		-- NOTE: Keep persistent cache files
	end

	if M.current_image and not M.album_cache[M.current_album] then
		kitty.delete_image(M.current_image, M.current_buf)
	end

	M.album_cache = {}
	M.current_image = nil
	M.current_album = nil
	M.is_loading = false
end

-- Display artwork in the buffer
-- width_chars and height_chars are optional - if not provided, use config defaults
-- album_name is used for caching (more efficient than per-track caching)
-- artwork_data is optional - if provided, use it directly instead of fetching from backend
--   artwork_data can be { url = "..." } for Spotify or { path = "..." } for Apple Music
function M.display(buf, row, col, album_name, width_chars, height_chars, artwork_data)
	if not config.options.artwork.enabled or not album_name then
		return
	end

	-- Save the buffer reference for cleanup
	M.current_buf = buf

	-- Use provided dimensions or fall back to config defaults (now cell-based)
	local max_width_chars = width_chars or config.options.artwork.max_width_chars
	local max_height_chars = height_chars or config.options.artwork.max_height_chars

	-- If already loading different album artwork, clear current display and return
	-- This prevents flashing of old cached artwork while new artwork loads
	if M.is_loading and album_name ~= M.current_album then
		if M.current_image and M.current_buf then
			kitty.delete_image(M.current_image, M.current_buf)
			M.current_image = nil
		end
		return
	end

	-- If this is the same album and image exists, just reposition it
	-- This is the key optimization: Kitty can reposition without re-transmitting!
	if album_name == M.current_album and M.current_image then
		kitty.display_image(M.current_image, row, col, max_width_chars, max_height_chars, buf)
		return
	end

	-- Check album cache (already loaded in Kitty)
	if M.album_cache[album_name] and M.album_cache[album_name].image then
		local cached = M.album_cache[album_name]
		M.current_image = cached.image
		M.current_album = album_name
		kitty.display_image(cached.image, row, col, max_width_chars, max_height_chars, buf)
		return
	end

	-- Check persistent file cache (main size only - never use thumbnail for main display)
	local has_cached, cached_path = cache.has_cached_artwork(album_name, "main")
	if has_cached then
		M.load_from_file(album_name, cached_path, buf, row, col, max_width_chars, max_height_chars)
		return
	end

	-- If already loading same album, skip (waiting for async to complete)
	if M.is_loading then
		return
	end

	-- Clear old image display reference
	M.clear()

	-- Mark as loading
	M.is_loading = true

	-- If artwork_data was provided (from state), use it directly
	if artwork_data then
		M.fetch_and_cache_artwork(artwork_data, album_name, buf, row, col, max_width_chars, max_height_chars)
		return
	end

	-- Otherwise, fetch artwork from backend
	local backend = require("vinyl").get_backend()
	if not backend then
		M.is_loading = false
		return
	end

	backend.get_artwork_async(function(artwork, err)
		if err or not artwork then
			M.is_loading = false
			return
		end

		M.fetch_and_cache_artwork(artwork, album_name, buf, row, col, max_width_chars, max_height_chars)
	end)
end

-- Fetch artwork from URL or file path and cache it
-- Extracted from display() to reduce duplication
function M.fetch_and_cache_artwork(artwork, album_name, buf, row, col, max_width_chars, max_height_chars)
	-- Use "main" size hint for high-quality main display artwork
	local png_path = cache.get_album_cache_path(album_name, "png", "main")

	-- Handle URL-based artwork (Spotify) vs file-based (Apple Music)
	if artwork.url then
		-- Download to temp file first to check content-type
		local temp_path = cache.get_album_cache_path(album_name, "tmp", "main")
		local curl_cmd = string.format('curl -s -L -w "\\n%%{content_type}" -o "%s" "%s"', temp_path, artwork.url)

		local output = vim.fn.system(curl_cmd)
		if vim.v.shell_error ~= 0 then
			M.is_loading = false
			return
		end

		-- Extract content-type from output
		local content_type = output:match("\n([^\n]+)$")

		-- Check if it's an image format we can handle
		if content_type and content_type:match("video") then
			M.is_loading = false
			return
		end

		-- Convert to PNG
		local convert_result = vim.fn.system(string.format('convert "%s" "%s" 2>&1', temp_path, png_path))
		if vim.v.shell_error ~= 0 then
			M.is_loading = false
			return
		end

		-- Clean up temp file
		vim.fn.delete(temp_path)
	elseif artwork.path then
		-- File-based artwork (Apple Music)
		local convert_result = vim.fn.system(string.format('convert "%s" "%s"', artwork.path, png_path))
		if vim.v.shell_error ~= 0 then
			M.is_loading = false
			return
		end
	else
		M.is_loading = false
		return
	end

	-- Verify PNG is valid
	local verify_result = vim.fn.system(string.format('file "%s"', png_path))
	if not verify_result:match("PNG image data") then
		M.is_loading = false
		return
	end

	-- Load and display
	vim.defer_fn(function()
		M.load_from_file(album_name, png_path, buf, row, col, max_width_chars, max_height_chars)
	end, 100)
end

-- Load artwork from file into Kitty and cache it
function M.load_from_file(album_name, png_path, buf, row, col, width, height)
	M.image_id_counter = M.image_id_counter + 1
	local img, load_err = kitty.load_image(png_path, {
		id = M.image_id_counter,
	})

	if not img then
		M.is_loading = false
		return
	end

	-- Cache in memory
	M.album_cache[album_name] = {
		image = img,
		cache_file = png_path,
	}

	-- Display
	kitty.display_image(img, row, col, width, height, buf)

	-- Save current state
	M.current_image = img
	M.current_album = album_name
	M.is_loading = false

	-- Force redraw
	vim.schedule(function()
		vim.cmd("redraw")
	end)
end

return M
