-- Artwork preloader - background loads next track's artwork from queue
-- Eliminates loading delays when skipping tracks
local cache = require("vinyl.cache")
local kitty = require("vinyl.kitty")

local M = {}

-- Initialize cache directory
cache.init()

-- Track which album is currently being preloaded
M.current_preload = nil

-- Preloaded artwork data (ready to display instantly)
-- Structure: { album_name = { image, cache_file } }
M.preloaded = {}

-- Preload artwork for next track in queue
-- queue: Queue data with upcoming_tracks array
-- callback: Optional callback when preload completes
function M.preload_next_track(queue, callback)
	if not queue or not queue.upcoming_tracks or #queue.upcoming_tracks == 0 then
		if callback then
			callback(false, "No upcoming tracks")
		end
		return
	end

	-- Get next track (first in upcoming list)
	local next_track = queue.upcoming_tracks[1]
	if not next_track or not next_track.album then
		if callback then
			callback(false, "No album info for next track")
		end
		return
	end

	local album_name = next_track.album

	-- Skip if already preloaded
	if M.preloaded[album_name] then
		if callback then
			callback(true, "Already preloaded")
		end
		return
	end

	-- Skip if already preloading this album
	if M.current_preload == album_name then
		if callback then
			callback(false, "Already preloading")
		end
		return
	end

	-- Check if already in persistent cache
	local has_cached, cached_path = cache.has_cached_artwork(album_name, "main")
	if has_cached then
		-- Load from cache into memory (fast!)
		M.current_preload = album_name
		M.load_from_file(album_name, cached_path, function(success)
			M.current_preload = nil
			if callback then
				callback(success, success and "Loaded from cache" or "Load failed")
			end
		end)
		return
	end

	-- Not cached - need to fetch artwork
	-- Check if artwork data was provided in queue (Spotify URLs)
	local artwork_data = next_track.artwork

	if artwork_data then
		-- Spotify: has artwork URL in queue data
		M.current_preload = album_name
		M.fetch_and_cache_artwork(artwork_data, album_name, function(success, err)
			M.current_preload = nil
			if callback then
				callback(success, err)
			end
		end)
	else
		-- Apple Music: fetch artwork using backend
		local backend_module = require("vinyl")
		local backend = backend_module.get_backend()

		if not backend or not backend.get_album_artwork_async then
			if callback then
				callback(false, "Backend does not support album artwork fetch")
			end
			return
		end

		M.current_preload = album_name

		backend.get_album_artwork_async(album_name, function(artwork, err)
			if err or not artwork then
				M.current_preload = nil
				if callback then
					callback(false, err or "Artwork fetch failed")
				end
				return
			end

			M.fetch_and_cache_artwork(artwork, album_name, function(success, fetch_err)
				M.current_preload = nil
				if callback then
					callback(success, fetch_err)
				end
			end)
		end)
	end
end

-- Fetch artwork from URL or file path and cache it (background operation)
-- Similar to main artwork.lua but for preloading
function M.fetch_and_cache_artwork(artwork, album_name, callback)
	-- Use "main" size hint for high-quality preloading
	local png_path = cache.get_album_cache_path(album_name, "png", "main")

	-- Handle URL-based artwork (Spotify) vs file-based (Apple Music)
	if artwork.url then
		-- Download to temp file first
		local temp_path = cache.get_album_cache_path(album_name, "tmp", "main")
		local curl_cmd = string.format('curl -s -L -w "\\n%%{content_type}" -o "%s" "%s"', temp_path, artwork.url)

		-- Run curl in background
		vim.fn.jobstart(curl_cmd, {
			on_exit = vim.schedule_wrap(function(_, exit_code)
				if exit_code ~= 0 then
					if callback then
						callback(false, "Download failed")
					end
					return
				end

				-- Read content-type from output
				local output = vim.fn.system("tail -n 1 " .. vim.fn.shellescape(temp_path))
				local content_type = vim.trim(output)

				-- Skip video formats
				if content_type and content_type:match("video") then
					vim.fn.delete(temp_path)
					if callback then
						callback(false, "Video format not supported")
					end
					return
				end

				-- Convert to PNG
				local convert_cmd = string.format('convert "%s" "%s" 2>&1', temp_path, png_path)
				vim.fn.jobstart(convert_cmd, {
					on_exit = vim.schedule_wrap(function(_, convert_code)
						vim.fn.delete(temp_path) -- Clean up temp file

						if convert_code ~= 0 then
							if callback then
								callback(false, "Image conversion failed")
							end
							return
						end

						-- Verify PNG is valid
						local verify_result = vim.fn.system(string.format('file "%s"', png_path))
						if not verify_result:match("PNG image data") then
							vim.fn.delete(png_path)
							if callback then
								callback(false, "Invalid PNG")
							end
							return
						end

						-- Load into memory
						M.load_from_file(album_name, png_path, callback)
					end),
				})
			end),
		})
	elseif artwork.path then
		-- File-based artwork (Apple Music) - convert to PNG
		local convert_cmd = string.format('convert "%s" "%s"', artwork.path, png_path)
		vim.fn.jobstart(convert_cmd, {
			on_exit = vim.schedule_wrap(function(_, exit_code)
				if exit_code ~= 0 then
					if callback then
						callback(false, "Conversion failed")
					end
					return
				end

				-- Verify PNG is valid
				local verify_result = vim.fn.system(string.format('file "%s"', png_path))
				if not verify_result:match("PNG image data") then
					vim.fn.delete(png_path)
					if callback then
						callback(false, "Invalid PNG")
					end
					return
				end

				-- Load into memory
				M.load_from_file(album_name, png_path, callback)
			end),
		})
	else
		if callback then
			callback(false, "No artwork source")
		end
	end
end

-- Load artwork from file into Kitty and cache it in memory
function M.load_from_file(album_name, png_path, callback)
	-- Load image into Kitty with stable ID based on album name
	-- Use same ID scheme as main artwork to prevent duplicates
	-- Range: 1000000-1999999 (matching main artwork.lua)
	local hash = vim.fn.sha256(album_name)
	local id = 1000000 + (hash:byte(1) * 3000) + (hash:byte(2) * 10) + hash:byte(3)
	local image_id = 1000000 + (id % 1000000)

	local img, load_err = kitty.load_image(png_path, {
		id = image_id,
	})

	if not img then
		if callback then
			callback(false, load_err or "Load failed")
		end
		return
	end

	-- Cache the image in memory (ready for instant display!)
	M.preloaded[album_name] = {
		image = img,
		cache_file = png_path,
	}

	if callback then
		callback(true, "Preloaded successfully")
	end
end

-- Get preloaded artwork for an album (instant access)
-- Returns: { image, cache_file } or nil
function M.get_preloaded(album_name)
	return M.preloaded[album_name]
end

-- Clear preloaded artwork from memory (but keep persistent cache)
function M.clear()
	for album_name, data in pairs(M.preloaded) do
		if data.image then
			-- Note: We don't delete the Kitty image here because it might still be displayed
			-- Kitty will handle cleanup when we load a different image with the same ID
		end
	end

	M.preloaded = {}
	M.current_preload = nil
end

return M
