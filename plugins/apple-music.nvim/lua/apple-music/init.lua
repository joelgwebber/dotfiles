local config = require('apple-music.config')
local highlights = require('apple-music.highlights')
local debug = require('apple-music.debug')
local ui = require('apple-music.ui')

-- Backends
local apple_music_backend = require('apple-music.backends.apple_music')
local spotify_backend = require('apple-music.backends.spotify')

-- Spotify auth
local spotify_auth = require('apple-music.spotify.auth')
local spotify_api = require('apple-music.spotify.api')
local spotify_state = require('apple-music.spotify.state')

local M = {}

-- Debug utilities
M.debug = debug

-- Debug: Show backend capabilities
function M.debug_backend()
  local backend = M.get_backend()
  if not backend then
    print("No backend available")
    return
  end

  print("=== Backend Info ===")
  print("Name: " .. backend.name)
  print("Display Name: " .. backend.display_name)

  if backend.capabilities then
    print("\nCapabilities:")
    print("- Playback control: " .. tostring(backend.capabilities.playback_control))
    print("- Volume control: " .. tostring(backend.capabilities.volume_control))
    print("- Queue access: " .. tostring(backend.capabilities.queue_access))
    print("- Queue accurate with shuffle: " .. tostring(backend.capabilities.queue_shuffle_accurate))
    print("- Library browsing: " .. tostring(backend.capabilities.library_browsing))
    print("- Playlist access: " .. tostring(backend.capabilities.playlist_access))
    print("- Seek: " .. tostring(backend.capabilities.seek))
    print("- Artwork: " .. tostring(backend.capabilities.artwork))
    print("- Streaming queue: " .. tostring(backend.capabilities.streaming_queue))
  else
    print("\nNo capabilities declared")
  end
end

-- Debug: Check queue data
function M.debug_queue()
  local backend = M.get_backend()
  if not backend then
    print("No backend available")
    return
  end

  print("Fetching queue data...")
  backend.get_queue_async(function(queue, err)
    if err then
      print("Queue error: " .. tostring(err))
      return
    end

    if not queue then
      print("Queue is nil")
      return
    end

    print("Queue Data:")
    print("- current_index: " .. tostring(queue.current_index))
    print("- total_tracks: " .. tostring(queue.total_tracks))
    print("- shuffle_enabled: " .. tostring(queue.shuffle_enabled))
    print("- upcoming_tracks count: " .. (queue.upcoming_tracks and #queue.upcoming_tracks or 0))

    if queue.upcoming_tracks and #queue.upcoming_tracks > 0 then
      print("\nUpcoming tracks:")
      for i, track in ipairs(queue.upcoming_tracks) do
        print(string.format("%d. %s - %s", i, track.name, track.artist))
      end
    end
  end)
end

-- Active backend
local current_backend = nil

-- Auto-detect and initialize backend
local function auto_detect_backend()
  -- Check for saved backend preference
  local preferred = spotify_state.load_backend_preference()

  if preferred == "spotify" then
    -- Try to use Spotify if it was preferred
    local spotify = spotify_backend.new()
    if spotify.available() and spotify.init({}) then
      return spotify
    end
    -- Preference was spotify but it's not available, fall through to auto-detect
  elseif preferred == "apple_music" then
    -- Try to use Apple Music if it was preferred
    local apple = apple_music_backend.new()
    if apple.available() and apple.init({}) then
      return apple
    end
    -- Preference was apple_music but it's not available, fall through to auto-detect
  end

  -- No preference or preferred backend unavailable, auto-detect
  -- Try Spotify first if authenticated
  local spotify = spotify_backend.new()
  if spotify.available() then
    if spotify.init({}) then
      return spotify
    end
  end

  -- Fall back to Apple Music if available
  local apple = apple_music_backend.new()
  if apple.available() then
    if apple.init({}) then
      return apple
    end
  end

  return nil
end

-- Get or initialize current backend
function M.get_backend()
  if not current_backend then
    current_backend = auto_detect_backend()
    if not current_backend then
      -- Build a helpful error message
      local msg = "No music backend available.\n"
      if vim.fn.has("mac") == 1 then
        msg = msg .. "- Apple Music: Not found or not running\n"
      else
        msg = msg .. "- Apple Music: Only available on macOS\n"
      end
      msg = msg .. "- Spotify: Run :lua require('apple-music').spotify_login()"
      vim.notify(msg, vim.log.levels.WARN)
    end
  end
  return current_backend
end

-- Force a specific backend
function M.use_backend(backend_name)
  if backend_name == "spotify" then
    local backend = spotify_backend.new()
    if backend.available() and backend.init({}) then
      current_backend = backend
      spotify_state.save_backend_preference("spotify")
      vim.notify("Switched to Spotify backend", vim.log.levels.INFO)
      return true
    else
      vim.notify("Spotify backend not available", vim.log.levels.ERROR)
      return false
    end
  elseif backend_name == "apple_music" then
    local backend = apple_music_backend.new()
    if backend.available() and backend.init({}) then
      current_backend = backend
      spotify_state.save_backend_preference("apple_music")
      vim.notify("Switched to Apple Music backend", vim.log.levels.INFO)
      return true
    else
      vim.notify("Apple Music backend not available", vim.log.levels.ERROR)
      return false
    end
  else
    vim.notify("Unknown backend: " .. backend_name, vim.log.levels.ERROR)
    return false
  end
end

-- Spotify authentication
function M.spotify_login()
  -- Show instructions first
  local instructions = [[
Spotify Setup Instructions:

1. Go to: https://developer.spotify.com/dashboard
2. Click "Create app"
3. Fill in details (name/description can be anything)
4. Set Redirect URI: http://127.0.0.1:8888/callback
5. Save and copy your Client ID and Client Secret

Press Enter to continue...]]

  vim.ui.input({
    prompt = instructions,
    default = ""
  }, function(continue)
    if continue == nil then
      return
    end

    -- Prompt for client credentials
    vim.ui.input({
      prompt = "Spotify Client ID (from dashboard): "
    }, function(client_id)
      if not client_id or client_id == "" then
        return
      end

      vim.ui.input({
        prompt = "Spotify Client Secret (from dashboard): "
      }, function(client_secret)
        if not client_secret or client_secret == "" then
          return
        end

        vim.ui.input({
          prompt = "Redirect URI (default: http://127.0.0.1:8888/callback): ",
          default = "http://127.0.0.1:8888/callback"
        }, function(redirect_uri)
          if not redirect_uri or redirect_uri == "" then
            redirect_uri = "http://127.0.0.1:8888/callback"
          end

          -- Save config
          spotify_api.set_config({
            client_id = client_id,
            client_secret = client_secret,
            redirect_uri = redirect_uri,
          })

          -- Extract port from redirect_uri
          local port = redirect_uri:match(":(%d+)")
          if not port then
            vim.notify("Invalid redirect URI - must include port (e.g., http://localhost:8888/callback)", vim.log.levels.ERROR)
            return
          end
          port = tonumber(port)

          -- Generate state for CSRF protection
          local state = spotify_auth.start_auth_flow(client_id, redirect_uri)

          -- Start callback server
          local oauth_server = require('apple-music.spotify.oauth_server')
          vim.notify("Starting OAuth callback server on port " .. port .. "...", vim.log.levels.INFO)

          oauth_server.start_callback_server(port, state, function(code, returned_state, err)
            if err then
              vim.notify("OAuth error: " .. err, vim.log.levels.ERROR)
              return
            end

            -- Verify state to prevent CSRF
            if returned_state ~= state then
              vim.notify("State mismatch - possible CSRF attack", vim.log.levels.ERROR)
              return
            end

            vim.notify("Authorization received, exchanging for token...", vim.log.levels.INFO)

            -- Exchange code for token
            spotify_auth.exchange_code_for_token(
              client_id,
              client_secret,
              code,
              redirect_uri,
              function(tokens, token_err)
                if token_err then
                  vim.notify("Token exchange error: " .. token_err, vim.log.levels.ERROR)
                  return
                end

                -- Save tokens
                spotify_api.set_tokens(tokens)
                spotify_api.init()

                vim.notify("✓ Spotify authentication successful!", vim.log.levels.INFO)

                -- Switch to Spotify backend
                M.use_backend("spotify")
              end
            )
          end)

          vim.notify(
            "Browser opened for Spotify authorization.\n" ..
            "After authorizing, you'll be redirected back automatically.",
            vim.log.levels.INFO
          )
        end)
      end)
    end)
  end)
end

function M.spotify_logout()
  spotify_state.clear_tokens()
  vim.notify("Logged out of Spotify", vim.log.levels.INFO)

  -- Switch to Apple Music if available
  current_backend = nil
  M.get_backend()
end

-- Debug: Check Spotify authentication status
function M.spotify_status()
  local tokens = spotify_state.load_tokens()
  local config = spotify_state.load_config()

  if not tokens then
    vim.notify("No Spotify tokens found", vim.log.levels.WARN)
    return
  end

  if not config then
    vim.notify("No Spotify config found", vim.log.levels.WARN)
    return
  end

  local status = string.format(
    "Spotify Authentication Status:\n" ..
    "- Tokens: %s\n" ..
    "- Config: %s\n" ..
    "- Access Token: %s...\n" ..
    "- Refresh Token: %s\n" ..
    "- Expires At: %s\n" ..
    "- Client ID: %s",
    tokens and "✓" or "✗",
    config and "✓" or "✗",
    tokens.access_token and tokens.access_token:sub(1, 20) or "none",
    tokens.refresh_token and "present" or "none",
    tokens.expires_at and os.date("%Y-%m-%d %H:%M:%S", tokens.expires_at) or "unknown",
    config.client_id or "none"
  )

  vim.notify(status, vim.log.levels.INFO)

  -- Also test if backend thinks it's available
  local backend = spotify_backend.new()
  vim.notify("Backend available: " .. tostring(backend.available()), vim.log.levels.INFO)
end

function M.setup(opts)
  config.setup(opts)
  highlights.setup()
end

-- UI controls
M.toggle_ui = ui.toggle
M.open_ui = ui.open
M.close_ui = ui.close

-- Playback controls (delegate to backend)
function M.play_pause()
  local backend = M.get_backend()
  if backend then
    backend.play_pause()
  end
end

function M.next_track()
  local backend = M.get_backend()
  if backend then
    backend.next_track()
  end
end

function M.previous_track()
  local backend = M.get_backend()
  if backend then
    backend.previous_track()
  end
end

function M.increase_volume()
  local backend = M.get_backend()
  if backend then
    backend.increase_volume()
  end
end

function M.decrease_volume()
  local backend = M.get_backend()
  if backend then
    backend.decrease_volume()
  end
end

function M.toggle_shuffle()
  local backend = M.get_backend()
  if backend then
    backend.toggle_shuffle()
  end
end

-- Library browsing using backend
-- We need to create new browse functions that use the backend's data and play functions
local search = require('apple-music.search')

function M.browse_tracks()
  local backend = M.get_backend()
  if not backend then
    return
  end

  backend.get_library_tracks_async(function(tracks, err)
    if err or not tracks then
      vim.notify("Failed to fetch tracks: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #tracks == 0 then
      vim.notify("No tracks found in library", vim.log.levels.WARN)
      return
    end

    -- Use telescope/fzf/vim.ui.select to pick a track
    search.show_picker(tracks, "Tracks", function(track)
      backend.play_track(track.id, function(success, play_err)
        if not success then
          vim.notify("Failed to play track: " .. (play_err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

function M.browse_albums()
  local backend = M.get_backend()
  if not backend then
    return
  end

  backend.get_library_albums_async(function(albums, err)
    if err or not albums then
      vim.notify("Failed to fetch albums: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #albums == 0 then
      vim.notify("No albums found in library", vim.log.levels.WARN)
      return
    end

    search.show_picker(albums, "Albums", function(album)
      backend.play_album(album.id, function(success, play_err)
        if not success then
          vim.notify("Failed to play album: " .. (play_err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

function M.browse_artists()
  local backend = M.get_backend()
  if not backend then
    return
  end

  backend.get_library_artists_async(function(artists, err)
    if err or not artists then
      vim.notify("Failed to fetch artists: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #artists == 0 then
      vim.notify("No artists found in library", vim.log.levels.WARN)
      return
    end

    search.show_picker(artists, "Artists", function(artist)
      backend.play_artist(artist.id, function(success, play_err)
        if not success then
          vim.notify("Failed to play artist: " .. (play_err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

function M.browse_playlists()
  local backend = M.get_backend()
  if not backend then
    return
  end

  backend.get_playlists_async(function(playlists, err)
    if err or not playlists then
      vim.notify("Failed to fetch playlists: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #playlists == 0 then
      vim.notify("No playlists found", vim.log.levels.WARN)
      return
    end

    search.show_picker(playlists, "Playlists", function(playlist)
      backend.play_playlist(playlist.id, function(success, play_err)
        if not success then
          vim.notify("Failed to play playlist: " .. (play_err or "unknown error"), vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

return M
