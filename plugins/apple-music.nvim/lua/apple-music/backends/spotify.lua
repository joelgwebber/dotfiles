-- Spotify backend implementation
local Backend = require('apple-music.backends.backend')
local api = require('apple-music.spotify.api')
local auth = require('apple-music.spotify.auth')
local state_manager = require('apple-music.spotify.state')

local M = {}

---@return Backend
function M.new()
  local backend = Backend.new()
  backend.name = "spotify"
  backend.display_name = "Spotify"

  -- Declare capabilities
  backend.capabilities = {
    playback_control = true, -- Requires Spotify Premium
    volume_control = true,
    queue_access = true,
    queue_shuffle_accurate = true, -- Can access actual playback queue via API
    library_browsing = true,
    playlist_access = true,
    seek = true,
    artwork = true, -- Provides URLs
    streaming_queue = true, -- Works for all tracks, not just library
  }

  -- Check if Spotify backend is available (has authentication)
  function backend.available()
    return api.init()
  end

  -- Initialize backend
  function backend.init(config)
    if not backend.available() then
      vim.notify(
        "Spotify not authenticated. Run :lua require('apple-music').spotify_login()",
        vim.log.levels.WARN
      )
      return false
    end
    return true
  end

  -- Get current playback state
  function backend.get_state_async(callback)
    api.get("/me/player", {}, function(response, err)
      if err then
        callback(nil, err)
        return
      end

      -- No active device
      if not response or not response.item then
        callback({
          playing = false,
          track_name = nil,
          artist = nil,
          album = nil,
        }, nil)
        return
      end

      local item = response.item
      local artists = {}
      if item.artists then
        for _, artist in ipairs(item.artists) do
          table.insert(artists, artist.name)
        end
      end

      -- Extract artwork URL (pick medium-sized image for better performance)
      -- Spotify returns images sorted by size (largest first)
      -- We want ~300-640px for terminal display
      local artwork_url = nil
      if item.album and item.album.images and #item.album.images > 0 then
        local images = item.album.images

        -- Try to find a medium-sized image (300-640px wide)
        for _, img in ipairs(images) do
          if img.width and img.width >= 300 and img.width <= 640 then
            artwork_url = img.url
            break
          end
        end

        -- Fallback to smallest image if no medium found
        if not artwork_url and #images > 0 then
          artwork_url = images[#images].url
        end
      end

      local state = {
        playing = response.is_playing or false,
        track_name = item.name,
        artist = table.concat(artists, ", "),
        album = item.album and item.album.name or nil,
        album_artist = item.album and item.album.artists and item.album.artists[1] and item.album.artists[1].name or nil,
        duration = item.duration_ms and (item.duration_ms / 1000) or 0,
        position = response.progress_ms and (response.progress_ms / 1000) or 0,
        volume = response.device and response.device.volume_percent or 0,
        shuffle = response.shuffle_state or false,
        repeat_mode = response.repeat_state or "off", -- "off", "track", "context"
        track_id = item.id,
        album_id = item.album and item.album.id or nil,
        artwork_url = artwork_url,
      }

      callback(state, nil)
    end)
  end

  -- Play/pause toggle
  function backend.play_pause(callback)
    -- First check current state
    backend.get_state_async(function(state, err)
      if err then
        if callback then callback(false, err) end
        return
      end

      local endpoint = state.playing and "/me/player/pause" or "/me/player/play"
      local method = "PUT"

      api.request(method, endpoint, {}, function(response, api_err)
        if api_err then
          if callback then callback(false, api_err) end
          return
        end
        if callback then callback(true, nil) end
      end)
    end)
  end

  -- Next track
  function backend.next_track(callback)
    api.post("/me/player/next", {}, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Previous track
  function backend.previous_track(callback)
    api.post("/me/player/previous", {}, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Seek to position (milliseconds)
  function backend.seek(position_ms, callback)
    local endpoint = string.format("/me/player/seek?position_ms=%d", position_ms)
    api.put(endpoint, {}, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Set volume (0-100)
  function backend.set_volume(volume, callback)
    volume = math.max(0, math.min(100, volume))
    local endpoint = string.format("/me/player/volume?volume_percent=%d", volume)
    api.put(endpoint, {}, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Increase volume
  function backend.increase_volume(callback)
    backend.get_state_async(function(state, err)
      if err or not state.volume then
        if callback then callback(false, err or "No volume info") end
        return
      end
      backend.set_volume(state.volume + 10, callback)
    end)
  end

  -- Decrease volume
  function backend.decrease_volume(callback)
    backend.get_state_async(function(state, err)
      if err or not state.volume then
        if callback then callback(false, err or "No volume info") end
        return
      end
      backend.set_volume(state.volume - 10, callback)
    end)
  end

  -- Toggle shuffle
  function backend.toggle_shuffle(callback)
    backend.get_state_async(function(state, err)
      if err then
        if callback then callback(false, err) end
        return
      end

      local new_state = not state.shuffle
      local endpoint = string.format("/me/player/shuffle?state=%s", new_state and "true" or "false")
      api.put(endpoint, {}, function(response, api_err)
        if callback then
          callback(not api_err, api_err)
        end
      end)
    end)
  end

  -- Toggle repeat mode (off -> context -> track -> off)
  function backend.toggle_repeat(callback)
    backend.get_state_async(function(state, err)
      if err then
        if callback then callback(false, err) end
        return
      end

      local next_mode
      if state.repeat_mode == "off" then
        next_mode = "context"
      elseif state.repeat_mode == "context" then
        next_mode = "track"
      else
        next_mode = "off"
      end

      local endpoint = string.format("/me/player/repeat?state=%s", next_mode)
      api.put(endpoint, {}, function(response, api_err)
        if callback then
          callback(not api_err, api_err)
        end
      end)
    end)
  end

  -- Get library tracks (paginated)
  function backend.get_library_tracks_async(callback)
    local all_tracks = {}

    local function fetch_page(url)
      -- Treat vim.NIL as nil (vim.NIL is truthy but represents JSON null)
      if url == vim.NIL then
        url = nil
      end

      local opts = url and { full_url = url } or {}
      local endpoint = url or "/me/tracks?limit=50"

      api.get(endpoint, opts, function(response, err)
        if err then
          callback(nil, err)
          return
        end

        -- Extract tracks
        if response.items then
          for _, item in ipairs(response.items) do
            local track = item.track
            if track then
              local artists = {}
              if track.artists then
                for _, artist in ipairs(track.artists) do
                  table.insert(artists, artist.name)
                end
              end

              table.insert(all_tracks, {
                id = track.id,
                name = track.name,
                artist = table.concat(artists, ", "),
                album = track.album and track.album.name or "",
                duration = track.duration_ms and (track.duration_ms / 1000) or 0,
              })
            end
          end
        end

        -- Check if there are more pages (vim.NIL is truthy, so check explicitly)
        if response.next and response.next ~= vim.NIL then
          fetch_page(response.next)
        else
          callback(all_tracks, nil)
        end
      end)
    end

    fetch_page(nil)
  end

  -- Get library albums (paginated)
  function backend.get_library_albums_async(callback)
    local all_albums = {}

    local function fetch_page(url)
      -- Treat vim.NIL as nil (vim.NIL is truthy but represents JSON null)
      if url == vim.NIL then
        url = nil
      end

      local opts = url and { full_url = url } or {}
      local endpoint = url or "/me/albums?limit=50"

      api.get(endpoint, opts, function(response, err)
        if err then
          callback(nil, err)
          return
        end

        if response.items then
          for _, item in ipairs(response.items) do
            local album = item.album
            if album then
              local artists = {}
              if album.artists then
                for _, artist in ipairs(album.artists) do
                  table.insert(artists, artist.name)
                end
              end

              table.insert(all_albums, {
                id = album.id,
                name = album.name,
                artist = table.concat(artists, ", "),
                track_count = album.total_tracks,
              })
            end
          end
        end

        if response.next and response.next ~= vim.NIL then
          fetch_page(response.next)
        else
          callback(all_albums, nil)
        end
      end)
    end

    fetch_page(nil)
  end

  -- Get library artists (no direct endpoint, extract from tracks)
  function backend.get_library_artists_async(callback)
    backend.get_library_tracks_async(function(tracks, err)
      if err then
        callback(nil, err)
        return
      end

      -- Extract unique artists
      local artist_map = {}
      for _, track in ipairs(tracks) do
        -- Split multiple artists
        for artist_name in track.artist:gmatch("[^,]+") do
          artist_name = artist_name:match("^%s*(.-)%s*$") -- trim whitespace
          artist_map[artist_name] = true
        end
      end

      local artists = {}
      for name, _ in pairs(artist_map) do
        table.insert(artists, {
          id = name, -- Use name as ID (we don't have artist IDs without searching)
          name = name,
        })
      end

      -- Sort alphabetically
      table.sort(artists, function(a, b) return a.name < b.name end)

      callback(artists, nil)
    end)
  end

  -- Get playlists
  function backend.get_playlists_async(callback)
    local all_playlists = {}

    local function fetch_page(url)
      -- Treat vim.NIL as nil (vim.NIL is truthy but represents JSON null)
      if url == vim.NIL then
        url = nil
      end

      local opts = url and { full_url = url } or {}
      local endpoint = url or "/me/playlists?limit=50"

      api.get(endpoint, opts, function(response, err)
        if err then
          callback(nil, err)
          return
        end

        if response.items then
          for _, playlist in ipairs(response.items) do
            table.insert(all_playlists, {
              id = playlist.id,
              name = playlist.name,
              track_count = playlist.tracks and playlist.tracks.total or 0,
            })
          end
        end

        if response.next and response.next ~= vim.NIL then
          fetch_page(response.next)
        else
          callback(all_playlists, nil)
        end
      end)
    end

    fetch_page(nil)
  end

  -- Play specific track
  function backend.play_track(track_id, callback)
    local body = {
      uris = { "spotify:track:" .. track_id }
    }
    api.put("/me/player/play", { body = body }, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Play specific album
  function backend.play_album(album_id, callback)
    local body = {
      context_uri = "spotify:album:" .. album_id,
      offset = { position = 0 }
    }
    api.put("/me/player/play", { body = body }, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- URL encode helper
  local function url_encode(str)
    if not str then return "" end
    str = string.gsub(str, "\n", "\r\n")
    str = string.gsub(str, "([^%w %-%_%.])",
      function(c) return string.format("%%%02X", string.byte(c)) end)
    str = string.gsub(str, " ", "+")
    return str
  end

  -- Play tracks by artist (we need to search for artist first)
  function backend.play_artist(artist_name, callback)
    -- Search for artist
    local query = url_encode(artist_name)
    local search_endpoint = string.format("/search?q=%s&type=artist&limit=1", query)

    api.get(search_endpoint, {}, function(search_response, search_err)
      if search_err then
        if callback then callback(false, search_err) end
        return
      end

      if not search_response.artists or not search_response.artists.items or #search_response.artists.items == 0 then
        if callback then callback(false, "Artist not found") end
        return
      end

      local artist_id = search_response.artists.items[1].id

      -- Get artist's top tracks
      local top_tracks_endpoint = string.format("/artists/%s/top-tracks?market=US", artist_id)
      api.get(top_tracks_endpoint, {}, function(tracks_response, tracks_err)
        if tracks_err then
          if callback then callback(false, tracks_err) end
          return
        end

        if not tracks_response.tracks or #tracks_response.tracks == 0 then
          if callback then callback(false, "No tracks found for artist") end
          return
        end

        -- Play the top tracks
        local track_uris = {}
        for _, track in ipairs(tracks_response.tracks) do
          table.insert(track_uris, track.uri)
        end

        local body = {
          uris = track_uris
        }
        api.put("/me/player/play", { body = body }, function(response, err)
          if callback then
            callback(not err, err)
          end
        end)
      end)
    end)
  end

  -- Play specific playlist
  function backend.play_playlist(playlist_id, callback)
    local body = {
      context_uri = "spotify:playlist:" .. playlist_id,
      offset = { position = 0 }
    }
    api.put("/me/player/play", { body = body }, function(response, err)
      if callback then
        callback(not err, err)
      end
    end)
  end

  -- Get artwork (Spotify provides URLs in state, so we return the URL)
  function backend.get_artwork_async(callback)
    backend.get_state_async(function(state, err)
      if err then
        callback(nil, err)
        return
      end

      if state.artwork_url then
        callback({ url = state.artwork_url }, nil)
      else
        callback(nil, "No artwork available")
      end
    end)
  end

  -- Get queue
  function backend.get_queue_async(callback)
    -- First get player state to know shuffle status
    backend.get_state_async(function(state, state_err)
      if state_err then
        if callback then callback(nil, state_err) end
        return
      end

      local shuffle_enabled = state.shuffle or false

      api.get("/me/player/queue", {}, function(response, err)
        if err then
          if callback then callback(nil, err) end
          return
        end

        local upcoming_tracks = {}
        if response.queue and response.queue ~= vim.NIL then
          for i, item in ipairs(response.queue) do
            if i > 10 then break end -- Limit to 10 tracks for UI

            local artists = {}
            if item.artists then
              for _, artist in ipairs(item.artists) do
                table.insert(artists, artist.name)
              end
            end

            table.insert(upcoming_tracks, {
              name = item.name,
              artist = table.concat(artists, ", "),
              album = item.album and item.album.name or nil,
            })
          end
        end

        -- Return queue in format UI expects
        local queue = {
          upcoming_tracks = upcoming_tracks,
          shuffle_enabled = shuffle_enabled,
          -- Spotify doesn't provide current_index/total_tracks in queue endpoint
        }

        if callback then
          callback(queue, nil)
        end
      end)
    end)
  end

  return backend
end

return M
