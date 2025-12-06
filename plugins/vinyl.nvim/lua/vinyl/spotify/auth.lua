-- Spotify OAuth 2.0 Authentication
-- Handles Authorization Code Flow with PKCE
local M = {}

-- OAuth endpoints
M.AUTH_URL = "https://accounts.spotify.com/authorize"
M.TOKEN_URL = "https://accounts.spotify.com/api/token"

-- Required scopes for our functionality
M.SCOPES = {
  "user-read-playback-state",     -- Read current playback state
  "user-modify-playback-state",   -- Control playback (Premium required)
  "user-read-currently-playing",  -- Read currently playing track
  "user-library-read",            -- Read saved tracks/albums
  "playlist-read-private",        -- Read private playlists
  "playlist-read-collaborative",  -- Read collaborative playlists
}

-- Generate random string for state parameter (CSRF protection)
local function generate_random_string(length)
  local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
  local result = {}
  for i = 1, length do
    local rand = math.random(1, #chars)
    table.insert(result, chars:sub(rand, rand))
  end
  return table.concat(result)
end

-- URL encode a string
local function url_encode(str)
  return str:gsub("([^A-Za-z0-9_%-%.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

-- Build authorization URL
function M.build_auth_url(client_id, redirect_uri, state)
  local scope = table.concat(M.SCOPES, " ")
  local params = {
    "response_type=code",
    "client_id=" .. url_encode(client_id),
    "scope=" .. url_encode(scope),
    "redirect_uri=" .. url_encode(redirect_uri),
    "state=" .. url_encode(state),
  }
  return M.AUTH_URL .. "?" .. table.concat(params, "&")
end

-- Extract authorization code from redirect URL
function M.extract_code_from_url(url)
  local code = url:match("code=([^&]+)")
  local state = url:match("state=([^&]+)")
  local error_param = url:match("error=([^&]+)")

  if error_param then
    return nil, nil, "Authorization failed: " .. error_param
  end

  if not code then
    return nil, nil, "No authorization code found in URL"
  end

  return code, state, nil
end

-- Exchange authorization code for access token
function M.exchange_code_for_token(client_id, client_secret, code, redirect_uri, callback)
  local body = string.format(
    "grant_type=authorization_code&code=%s&redirect_uri=%s",
    url_encode(code),
    url_encode(redirect_uri)
  )

  -- Base64 encode client_id:client_secret for Basic auth
  local credentials = client_id .. ":" .. client_secret
  local auth_header = "Basic " .. vim.fn.system("printf %s " .. vim.fn.shellescape(credentials) .. " | base64"):gsub("\n", "")

  local curl_cmd = {
    "curl",
    "-s",
    "-X", "POST",
    M.TOKEN_URL,
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "-H", "Authorization: " .. auth_header,
    "-d", body,
  }

  vim.system(curl_cmd, { text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      callback(nil, "Failed to exchange code for token: " .. (result.stderr or "unknown error"))
      return
    end

    local ok, response = pcall(vim.json.decode, result.stdout)
    if not ok then
      callback(nil, "Failed to parse token response: " .. result.stdout)
      return
    end

    if response.error then
      callback(nil, "Token exchange error: " .. response.error .. " - " .. (response.error_description or ""))
      return
    end

    -- Extract tokens
    local tokens = {
      access_token = response.access_token,
      refresh_token = response.refresh_token,
      expires_in = response.expires_in,
      token_type = response.token_type,
      scope = response.scope,
      expires_at = os.time() + (response.expires_in or 3600),
    }

    callback(tokens, nil)
  end))
end

-- Refresh access token using refresh token
function M.refresh_access_token(client_id, client_secret, refresh_token, callback)
  local body = string.format(
    "grant_type=refresh_token&refresh_token=%s",
    refresh_token
  )

  local credentials = client_id .. ":" .. client_secret
  local auth_header = "Basic " .. vim.fn.system("printf %s " .. vim.fn.shellescape(credentials) .. " | base64"):gsub("\n", "")

  local curl_cmd = {
    "curl",
    "-s",
    "-X", "POST",
    M.TOKEN_URL,
    "-H", "Content-Type: application/x-www-form-urlencoded",
    "-H", "Authorization: " .. auth_header,
    "-d", body,
  }

  vim.system(curl_cmd, { text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      callback(nil, "Failed to refresh token: " .. (result.stderr or "unknown error"))
      return
    end

    local ok, response = pcall(vim.json.decode, result.stdout)
    if not ok then
      callback(nil, "Failed to parse refresh response: " .. result.stdout)
      return
    end

    if response.error then
      callback(nil, "Token refresh error: " .. response.error .. " - " .. (response.error_description or ""))
      return
    end

    -- Build updated tokens (keep existing refresh_token if not provided)
    local tokens = {
      access_token = response.access_token,
      refresh_token = response.refresh_token or refresh_token,
      expires_in = response.expires_in,
      token_type = response.token_type,
      scope = response.scope,
      expires_at = os.time() + (response.expires_in or 3600),
    }

    callback(tokens, nil)
  end))
end

-- Check if token is expired or about to expire (within 5 minutes)
function M.is_token_expired(tokens)
  if not tokens or not tokens.expires_at then
    return true
  end
  return os.time() >= (tokens.expires_at - 300)
end

-- Start OAuth flow (interactive)
function M.start_auth_flow(client_id, redirect_uri)
  local state = generate_random_string(16)
  local auth_url = M.build_auth_url(client_id, redirect_uri, state)

  -- Open browser
  local open_cmd
  if vim.fn.has("mac") == 1 then
    open_cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    open_cmd = "xdg-open"
  else
    open_cmd = "start"
  end

  vim.fn.system(open_cmd .. " " .. vim.fn.shellescape(auth_url))

  vim.notify(
    "Opening browser for Spotify authorization...\n" ..
    "After authorizing, paste the redirect URL here.",
    vim.log.levels.INFO
  )

  return state
end

return M
