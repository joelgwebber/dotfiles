-- Persistent state cache for instant startup
-- Saves last known player state to disk for fast UI rendering
local M = {}

-- Cache file location
local function get_cache_file()
	local cache_dir = vim.fn.expand("~/.cache/vinyl-nvim")
	vim.fn.mkdir(cache_dir, "p")
	return cache_dir .. "/last_state.json"
end

-- Save current state to disk (called after each successful state fetch)
-- state: Player state object with track_name, artist, album, position, duration, volume, etc.
function M.save_state(state)
	if not state then
		return false
	end

	local cache_file = get_cache_file()

	-- Add timestamp for staleness detection
	local cache_data = {
		state = state,
		timestamp = os.time(),
	}

	local ok, json = pcall(vim.json.encode, cache_data)
	if not ok then
		return false
	end

	local ok2, err = pcall(vim.fn.writefile, { json }, cache_file)
	if not ok2 then
		return false
	end

	return true
end

-- Load cached state from disk
-- max_age_seconds: Maximum age in seconds for cache to be valid (default: 3600 = 1 hour)
-- Returns: { state, is_stale } or nil if no cache or error
function M.load_state(max_age_seconds)
	max_age_seconds = max_age_seconds or 3600 -- Default: 1 hour

	local cache_file = get_cache_file()

	if vim.fn.filereadable(cache_file) == 0 then
		return nil
	end

	local ok, content = pcall(vim.fn.readfile, cache_file)
	if not ok or not content or #content == 0 then
		return nil
	end

	local ok2, cache_data = pcall(vim.json.decode, table.concat(content, "\n"))
	if not ok2 or not cache_data or not cache_data.state then
		return nil
	end

	-- Check if cache is too old
	local age = os.time() - (cache_data.timestamp or 0)
	local is_stale = age > max_age_seconds

	return {
		state = cache_data.state,
		is_stale = is_stale,
		age_seconds = age,
	}
end

-- Clear cached state (optional - for logout or backend switch)
function M.clear()
	local cache_file = get_cache_file()
	if vim.fn.filereadable(cache_file) == 1 then
		vim.fn.delete(cache_file)
	end
end

return M
