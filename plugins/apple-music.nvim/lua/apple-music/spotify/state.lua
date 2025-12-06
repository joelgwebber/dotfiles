-- Spotify state management (token storage)
local M = {}

-- Storage location for tokens
local function get_token_file()
  local data_dir = vim.fn.stdpath("data")
  local spotify_dir = data_dir .. "/apple-music-nvim"
  vim.fn.mkdir(spotify_dir, "p")
  return spotify_dir .. "/spotify_tokens.json"
end

-- Load tokens from disk
function M.load_tokens()
  local token_file = get_token_file()

  if vim.fn.filereadable(token_file) == 0 then
    return nil
  end

  local ok, content = pcall(vim.fn.readfile, token_file)
  if not ok then
    return nil
  end

  local ok2, tokens = pcall(vim.json.decode, table.concat(content, "\n"))
  if not ok2 then
    return nil
  end

  return tokens
end

-- Save tokens to disk
function M.save_tokens(tokens)
  local token_file = get_token_file()

  local ok, json = pcall(vim.json.encode, tokens)
  if not ok then
    return false, "Failed to encode tokens"
  end

  local ok2, err = pcall(vim.fn.writefile, { json }, token_file)
  if not ok2 then
    return false, "Failed to write tokens: " .. tostring(err)
  end

  -- Make file readable only by user
  vim.fn.system(string.format("chmod 600 %s", vim.fn.shellescape(token_file)))

  return true
end

-- Clear tokens (logout)
function M.clear_tokens()
  local token_file = get_token_file()
  if vim.fn.filereadable(token_file) == 1 then
    vim.fn.delete(token_file)
  end
end

-- Get config file location
local function get_config_file()
  local data_dir = vim.fn.stdpath("data")
  local spotify_dir = data_dir .. "/apple-music-nvim"
  vim.fn.mkdir(spotify_dir, "p")
  return spotify_dir .. "/spotify_config.json"
end

-- Load Spotify client configuration (client_id, redirect_uri)
function M.load_config()
  local config_file = get_config_file()

  if vim.fn.filereadable(config_file) == 0 then
    return nil
  end

  local ok, content = pcall(vim.fn.readfile, config_file)
  if not ok then
    return nil
  end

  local ok2, config = pcall(vim.json.decode, table.concat(content, "\n"))
  if not ok2 then
    return nil
  end

  return config
end

-- Save Spotify client configuration
function M.save_config(config)
  local config_file = get_config_file()

  local ok, json = pcall(vim.json.encode, config)
  if not ok then
    return false, "Failed to encode config"
  end

  local ok2, err = pcall(vim.fn.writefile, { json }, config_file)
  if not ok2 then
    return false, "Failed to write config: " .. tostring(err)
  end

  return true
end

-- Get backend preference file location
local function get_backend_pref_file()
  local data_dir = vim.fn.stdpath("data")
  local music_dir = data_dir .. "/apple-music-nvim"
  vim.fn.mkdir(music_dir, "p")
  return music_dir .. "/backend_preference.txt"
end

-- Load backend preference
function M.load_backend_preference()
  local pref_file = get_backend_pref_file()

  if vim.fn.filereadable(pref_file) == 0 then
    return nil
  end

  local ok, content = pcall(vim.fn.readfile, pref_file)
  if not ok or not content or #content == 0 then
    return nil
  end

  return vim.trim(content[1])
end

-- Save backend preference
function M.save_backend_preference(backend_name)
  local pref_file = get_backend_pref_file()

  local ok, err = pcall(vim.fn.writefile, { backend_name }, pref_file)
  if not ok then
    return false, "Failed to write backend preference: " .. tostring(err)
  end

  return true
end

return M
