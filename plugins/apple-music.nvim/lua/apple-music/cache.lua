-- Persistent cache management for album artwork
local M = {}

-- Cache directory in user's home
M.cache_dir = vim.fn.expand('~/.cache/apple-music-nvim')

-- Ensure cache directory exists
function M.init()
  vim.fn.mkdir(M.cache_dir, 'p')
end

-- Generate safe filename from album name
function M.get_album_cache_path(album_name, format)
  format = format or 'png'
  -- Create a safe filename from album name
  local safe_name = album_name:gsub('[^%w%s%-]', ''):gsub('%s+', '-'):lower()
  -- Truncate if too long (keep first 100 chars)
  if #safe_name > 100 then
    safe_name = safe_name:sub(1, 100)
  end
  -- Add a hash to ensure uniqueness
  local hash = vim.fn.sha256(album_name):sub(1, 8)
  return string.format('%s/%s-%s.%s', M.cache_dir, safe_name, hash, format)
end

-- Check if cached file exists and is valid
function M.has_cached_artwork(album_name)
  local path = M.get_album_cache_path(album_name, 'png')
  if vim.fn.filereadable(path) == 1 then
    -- Verify it's a valid PNG
    local result = vim.fn.system(string.format('file "%s"', path))
    return result:match('PNG image data') ~= nil, path
  end
  return false, nil
end

-- Clean old cache files (optional maintenance function)
-- Removes files older than days_old
function M.clean_old_files(days_old)
  days_old = days_old or 30
  local cutoff = os.time() - (days_old * 24 * 60 * 60)

  local files = vim.fn.globpath(M.cache_dir, '*.png', false, true)
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
