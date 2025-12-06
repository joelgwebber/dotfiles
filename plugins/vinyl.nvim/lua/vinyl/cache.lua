-- Persistent cache management for album artwork
local M = {}

-- Cache directory in user's home
M.cache_dir = vim.fn.expand("~/.cache/vinyl-nvim")

-- Ensure cache directory exists
function M.init()
	vim.fn.mkdir(M.cache_dir, "p")
end

-- Generate safe filename from album name
-- size_hint: "main" for full-size artwork, "thumbnail" for queue thumbnails
function M.get_album_cache_path(album_name, format, size_hint)
	format = format or "png"
	size_hint = size_hint or "main"

	-- Create a safe filename from album name
	local safe_name = album_name:gsub("[^%w%s%-]", ""):gsub("%s+", "-"):lower()
	-- Truncate if too long (keep first 100 chars)
	if #safe_name > 100 then
		safe_name = safe_name:sub(1, 100)
	end
	-- Add a hash to ensure uniqueness
	local hash = vim.fn.sha256(album_name):sub(1, 8)

	-- Include size hint in filename to prevent cache pollution
	-- main: high-res for main display, thumbnail: low-res for queue
	return string.format("%s/%s-%s-%s.%s", M.cache_dir, safe_name, hash, size_hint, format)
end

-- Check if cached file exists and is valid
-- size_hint: "main" for full-size, "thumbnail" for queue, or "any" to check both (prefer main)
function M.has_cached_artwork(album_name, size_hint)
	size_hint = size_hint or "main"

	-- If "any", check for main first (higher quality), then thumbnail
	if size_hint == "any" then
		local main_has, main_path = M.has_cached_artwork(album_name, "main")
		if main_has then
			return true, main_path, "main"
		end
		local thumb_has, thumb_path = M.has_cached_artwork(album_name, "thumbnail")
		if thumb_has then
			return true, thumb_path, "thumbnail"
		end
		return false, nil, nil
	end

	local path = M.get_album_cache_path(album_name, "png", size_hint)
	if vim.fn.filereadable(path) == 1 then
		-- Verify it's a valid PNG
		local result = vim.fn.system(string.format('file "%s"', path))
		return result:match("PNG image data") ~= nil, path
	end
	return false, nil
end

-- Clean old cache files (optional maintenance function)
-- Removes files older than days_old
function M.clean_old_files(days_old)
	days_old = days_old or 30
	local cutoff = os.time() - (days_old * 24 * 60 * 60)

	local files = vim.fn.globpath(M.cache_dir, "*.png", false, true)
	local removed = 0

	for _, file in ipairs(files) do
		local mtime = vim.fn.getftime(file)
		if mtime > 0 and mtime < cutoff then
			vim.fn.delete(file)
			removed = removed + 1
		end
	end

	return removed
end

return M
