-- Spotify Web API client with rate limiting
local auth = require("vinyl.spotify.auth")
local state_manager = require("vinyl.spotify.state")

local M = {}

-- API base URL
M.BASE_URL = "https://api.spotify.com/v1"

-- Rate limiting state
local rate_limit = {
	is_limited = false,
	retry_after = 0,
	last_request = 0,
	min_interval_ms = 100, -- Minimum time between requests (100ms = 10 req/sec max)
}

-- Tokens and config
local tokens = nil
local config = nil

-- Initialize API client
function M.init()
	tokens = state_manager.load_tokens()
	config = state_manager.load_config()
	return tokens ~= nil and config ~= nil
end

-- Check if we're authenticated
function M.is_authenticated()
	return tokens ~= nil and tokens.access_token ~= nil
end

-- Get current tokens
function M.get_tokens()
	return tokens
end

-- Set tokens (after authentication)
function M.set_tokens(new_tokens)
	tokens = new_tokens
	state_manager.save_tokens(tokens)
end

-- Get config
function M.get_config()
	return config
end

-- Set config
function M.set_config(new_config)
	config = new_config
	state_manager.save_config(config)
end

-- Check if we should wait due to rate limiting
local function check_rate_limit()
	local now = vim.loop.now()

	-- Check retry-after from 429 response
	if rate_limit.is_limited and now < rate_limit.retry_after then
		local wait_ms = rate_limit.retry_after - now
		return false, wait_ms
	end

	-- Check minimum interval between requests
	local elapsed = now - rate_limit.last_request
	if elapsed < rate_limit.min_interval_ms then
		local wait_ms = rate_limit.min_interval_ms - elapsed
		return false, wait_ms
	end

	rate_limit.is_limited = false
	return true, 0
end

-- Update rate limit state after request
local function update_rate_limit(retry_after_seconds)
	local now = vim.loop.now()
	rate_limit.last_request = now

	if retry_after_seconds then
		rate_limit.is_limited = true
		rate_limit.retry_after = now + (retry_after_seconds * 1000)
	end
end

-- Refresh token if expired
local function ensure_valid_token(callback)
	if not tokens then
		callback(nil, "Not authenticated")
		return
	end

	if not auth.is_token_expired(tokens) then
		callback(tokens.access_token, nil)
		return
	end

	-- Token expired, refresh it
	if not config or not config.client_id or not config.client_secret then
		callback(nil, "Missing client configuration")
		return
	end

	auth.refresh_access_token(config.client_id, config.client_secret, tokens.refresh_token, function(new_tokens, err)
		if err then
			callback(nil, "Failed to refresh token: " .. err)
			return
		end

		tokens = new_tokens
		state_manager.save_tokens(tokens)
		callback(tokens.access_token, nil)
	end)
end

-- Make an authenticated API request
function M.request(method, endpoint, opts, callback)
	opts = opts or {}

	-- Check rate limit
	local can_proceed, wait_ms = check_rate_limit()
	if not can_proceed then
		-- Schedule retry after wait time
		vim.defer_fn(function()
			M.request(method, endpoint, opts, callback)
		end, wait_ms)
		return
	end

	-- Ensure we have a valid token
	ensure_valid_token(function(access_token, err)
		if err then
			callback(nil, err)
			return
		end

		local url = opts.full_url or (M.BASE_URL .. endpoint)
		local headers = {
			"Authorization: Bearer " .. access_token,
			"Content-Type: application/json",
		}

		local curl_cmd = {
			"curl",
			"-s",
			"-X",
			method,
			"-w",
			"\n%{http_code}", -- Include HTTP status code
		}

		-- Add headers
		for _, header in ipairs(headers) do
			table.insert(curl_cmd, "-H")
			table.insert(curl_cmd, header)
		end

		-- Add body for POST/PUT
		if opts.body and (method == "POST" or method == "PUT") then
			local ok, json = pcall(vim.json.encode, opts.body)
			if ok then
				table.insert(curl_cmd, "-d")
				table.insert(curl_cmd, json)
			end
		end

		-- Add URL
		table.insert(curl_cmd, url)

		vim.system(
			curl_cmd,
			{ text = true },
			vim.schedule_wrap(function(result)
				if result.code ~= 0 then
					update_rate_limit(nil)
					callback(nil, "Request failed: " .. (result.stderr or "unknown error"))
					return
				end

				-- Split response body and status code
				local output = result.stdout
				local body, status_code = output:match("^(.*)%s+(%d+)$")

				if not status_code then
					update_rate_limit(nil)
					callback(nil, "Failed to parse response")
					return
				end

				status_code = tonumber(status_code)

				-- Handle rate limiting
				if status_code == 429 then
					-- Extract Retry-After header (we'd need to use -i flag and parse headers)
					-- For now, use exponential backoff (start with 1 second)
					local retry_after = 1
					update_rate_limit(retry_after)
					callback(nil, string.format("Rate limited (429). Retrying after %d seconds", retry_after))
					return
				end

				update_rate_limit(nil)

				-- Handle errors
				if status_code >= 400 then
					local ok, error_response = pcall(vim.json.decode, body)
					if ok and error_response.error then
						local error_msg = error_response.error.message or "Unknown error"
						callback(nil, string.format("API error (%d): %s", status_code, error_msg))
					else
						callback(nil, string.format("HTTP error %d: %s", status_code, body))
					end
					return
				end

				-- Parse successful response
				if body and body ~= "" then
					local ok, response = pcall(vim.json.decode, body)
					if ok then
						callback(response, nil)
					else
						callback(nil, "Failed to parse response JSON: " .. body)
					end
				else
					callback({}, nil) -- Empty response is OK for some endpoints
				end
			end)
		)
	end)
end

-- Convenience methods for common HTTP verbs
function M.get(endpoint, opts, callback)
	M.request("GET", endpoint, opts, callback)
end

function M.post(endpoint, opts, callback)
	M.request("POST", endpoint, opts, callback)
end

function M.put(endpoint, opts, callback)
	M.request("PUT", endpoint, opts, callback)
end

function M.delete(endpoint, opts, callback)
	M.request("DELETE", endpoint, opts, callback)
end

return M
