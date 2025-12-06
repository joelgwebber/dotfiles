local M = {}

-- Async AppleScript execution using vim.system (Neovim 0.8+)
local function execute_applescript_async(script, callback)
  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    function(result)
      if result.code == 0 then
        vim.schedule(function()
          callback(vim.trim(result.stdout))
        end)
      else
        vim.schedule(function()
          callback(nil, result.stderr)
        end)
      end
    end
  )
end

-- Synchronous version for simple commands (play/pause, etc.)
local function execute_applescript(script)
  local result = vim.system({ 'osascript', '-e', script }, { text = true }):wait()
  if result.code == 0 then
    return vim.trim(result.stdout)
  end
  return nil, result.stderr
end

-- Get upcoming tracks from current playlist or album
-- Returns: { current_index, total_tracks, shuffle_enabled, upcoming_tracks[] }
-- Each track has: name, artist, album
function M.get_queue_async(callback)
  local script = [[
    tell application "Music"
      if player state is stopped then
        return "stopped"
      end if

      set shuffleOn to shuffle enabled
      set currentTrack to current track
      set currentTrackID to database ID of currentTrack

      -- Try 1: Access current playlist (works when playing from a playlist)
      try
        set currentPL to current playlist
        set plTracks to tracks of currentPL
        set trackCount to count of plTracks

        -- Find current track index in playlist
        set currentIndex to 0
        repeat with i from 1 to trackCount
          try
            if database ID of (item i of plTracks) = currentTrackID then
              set currentIndex to i
              exit repeat
            end if
          end try
        end repeat

        if currentIndex > 0 then
          -- Success! Build output from playlist
          set output to currentIndex as string
          set output to output & tab & trackCount as string
          set output to output & tab & (shuffleOn as string)

          if not shuffleOn then
            set endIndex to currentIndex + 5
            if endIndex > trackCount then
              set endIndex to trackCount
            end if

            repeat with i from (currentIndex + 1) to endIndex
              try
                set t to item i of plTracks
                set output to output & tab & (name of t)
                set output to output & tab & (artist of t)
                set output to output & tab & (album of t)
              end try
            end repeat
          end if

          return output
        end if
      end try

      -- Try 2: Fall back to library search by album (works when playing album directly)
      try
        set albumName to album of currentTrack
        set artistName to artist of currentTrack
        set lib to library playlist 1
        set matchingTracks to (every track of lib whose album is albumName and artist is artistName)

        if (count of matchingTracks) = 0 then
          return "error|No queue available"
        end if

        -- Find current track in album tracks
        set currentIndex to 0
        repeat with i from 1 to (count of matchingTracks)
          if database ID of (item i of matchingTracks) = currentTrackID then
            set currentIndex to i
            exit repeat
          end if
        end repeat

        if currentIndex = 0 then
          return "error|No queue available"
        end if

        -- Build output from album tracks
        set output to currentIndex as string
        set output to output & tab & (count of matchingTracks) as string
        set output to output & tab & (shuffleOn as string)

        if not shuffleOn then
          set endIndex to currentIndex + 5
          if endIndex > (count of matchingTracks) then
            set endIndex to count of matchingTracks
          end if

          repeat with i from (currentIndex + 1) to endIndex
            set t to item i of matchingTracks
            set output to output & tab & (name of t)
            set output to output & tab & (artist of t)
            set output to output & tab & (album of t)
          end repeat
        end if

        return output
      on error errMsg
        return "error|" & errMsg
      end try
    end tell
  ]]

  execute_applescript_async(script, function(result, err)
    if err or not result then
      callback(nil, "AppleScript error: " .. tostring(err))
      return
    end

    -- Check for error conditions
    if result:match("^stopped") then
      callback(nil, "Player is stopped")
      return
    end

    if result:match("^notfound") then
      local parts = vim.split(result, '|')
      local playlist_name = parts[2] or "unknown"
      local track_count = parts[3] or "unknown"
      callback(nil, string.format("Current track not found in playlist '%s' (%s tracks)", playlist_name, track_count))
      return
    end

    if result:match("^error") then
      local parts = vim.split(result, '|')
      callback(nil, "Queue fetch error: " .. (parts[2] or "unknown"))
      return
    end

    local parts = vim.split(result, '\t')
    local queue = {}

    queue.current_index = tonumber(parts[1])
    queue.total_tracks = tonumber(parts[2])
    queue.shuffle_enabled = (parts[3] == "true")
    queue.upcoming_tracks = {}

    -- Parse upcoming tracks (triples of name, artist, album) - only present if shuffle is off
    for i = 4, #parts, 3 do
      if parts[i] and parts[i+1] and parts[i+2] then
        table.insert(queue.upcoming_tracks, {
          name = parts[i],
          artist = parts[i+1],
          album = parts[i+2],
        })
      end
    end

    callback(queue)
  end)
end

-- Batched state query - ONE AppleScript call returns all data
-- Returns tab-delimited with extended metadata
function M.get_state_async(callback)
  local script = [[
    tell application "Music"
      if it is not running then
        return "stopped"
      end if

      set output to ""
      set output to output & (player state as string)

      if player state is not stopped then
        set t to current track

        -- Basic info
        set output to output & tab & (name of t)
        set output to output & tab & (artist of t)
        set output to output & tab & (album of t)
        set output to output & tab & (duration of t)
        set output to output & tab & (player position)

        -- Genre
        try
          set output to output & tab & (genre of t)
        on error
          set output to output & tab & ""
        end try

        -- Year
        try
          set output to output & tab & (year of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Rating
        try
          set output to output & tab & (rating of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Track number
        try
          set output to output & tab & (track number of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Track count
        try
          set output to output & tab & (track count of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Disc number
        try
          set output to output & tab & (disc number of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Disc count
        try
          set output to output & tab & (disc count of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Played count
        try
          set output to output & tab & (played count of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Bit rate
        try
          set output to output & tab & (bit rate of t as string)
        on error
          set output to output & tab & "0"
        end try

        -- Favorited
        try
          set output to output & tab & (favorited of t as string)
        on error
          set output to output & tab & "false"
        end try

        -- Disliked
        try
          set output to output & tab & (disliked of t as string)
        on error
          set output to output & tab & "false"
        end try

        -- Composer
        try
          set output to output & tab & (composer of t)
        on error
          set output to output & tab & ""
        end try

        -- Album artist
        try
          set output to output & tab & (album artist of t)
        on error
          set output to output & tab & ""
        end try

        -- Artwork count
        set output to output & tab & (count of artworks of t) as string

      else
        -- Stopped state - return empty values
        set output to output & tab & "" & tab & "" & tab & "" & tab & "0" & tab & "0"
        set output to output & tab & "" & tab & "0" & tab & "0" & tab & "0" & tab & "0"
        set output to output & tab & "0" & tab & "0" & tab & "0" & tab & "0"
        set output to output & tab & "false" & tab & "false" & tab & "" & tab & "" & tab & "0"
      end if

      set output to output & tab & (sound volume)

      return output
    end tell
  ]]

  execute_applescript_async(script, function(result, err)
    if err or not result then
      callback({})
      return
    end

    local parts = vim.split(result, '\t')
    local state = {}

    state.player_state = parts[1]

    if state.player_state ~= 'stopped' and #parts >= 21 then
      state.track_name = parts[2] ~= '' and parts[2] or nil
      state.artist = parts[3] ~= '' and parts[3] or nil
      state.album = parts[4] ~= '' and parts[4] or nil
      state.duration = tonumber(parts[5])
      state.position = tonumber(parts[6])

      -- Extended metadata
      state.genre = parts[7] ~= '' and parts[7] or nil
      state.year = tonumber(parts[8]) or nil
      state.rating = tonumber(parts[9]) or 0
      state.track_number = tonumber(parts[10]) or 0
      state.track_count = tonumber(parts[11]) or 0
      state.disc_number = tonumber(parts[12]) or 0
      state.disc_count = tonumber(parts[13]) or 0
      state.played_count = tonumber(parts[14]) or 0
      state.bit_rate = tonumber(parts[15]) or 0
      state.favorited = parts[16] == 'true'
      state.disliked = parts[17] == 'true'
      state.composer = parts[18] ~= '' and parts[18] or nil
      state.album_artist = parts[19] ~= '' and parts[19] or nil
      state.artwork_count = tonumber(parts[20]) or 0
      state.volume = tonumber(parts[21])
    else
      state.volume = tonumber(parts[21] or parts[2])
    end

    callback(state)
  end)
end

-- Extract artwork for a specific album (from any track with that album name)
-- Returns: { path, format } or (nil, error)
function M.get_album_artwork_async(album_name, callback)
  local script = string.format([[
    tell application "Music"
      if player state is stopped then
        return "stopped" & tab & ""
      end if

      set currentPL to current playlist
      set allTracks to every track of currentPL

      -- Find first track with this album
      repeat with t in allTracks
        if album of t = "%s" then
          if (count of artworks of t) > 0 then
            set artData to raw data of artwork 1 of t
            set artFormat to format of artwork 1 of t
            -- Use album name in temp file to enable caching
            set safeAlbumName to do shell script "echo " & quoted form of "%s" & " | sed 's/[^a-zA-Z0-9]/-/g'"
            set tempFile to "/tmp/apple-music-queue-" & safeAlbumName & ".jpg"

            try
              set fileRef to open for access tempFile with write permission
              set eof fileRef to 0
              write artData to fileRef
              close access fileRef
              return tempFile & tab & artFormat
            on error errMsg
              try
                close access tempFile
              end try
              return "error" & tab & errMsg
            end try
          else
            return "noartwork" & tab & ""
          end if
        end if
      end repeat

      return "notfound" & tab & ""
    end tell
  ]], album_name, album_name)

  execute_applescript_async(script, function(result, err)
    if err or not result then
      callback(nil, err)
      return
    end

    local parts = vim.split(result, '\t')
    local status = parts[1]

    if status == 'error' or status == 'noartwork' or status == 'stopped' or status == 'notfound' then
      callback(nil, parts[2] or status)
    else
      -- Success - parts[1] is file path, parts[2] is format
      callback({ path = parts[1], format = parts[2] })
    end
  end)
end

-- Extract artwork to a temp file
function M.get_artwork_async(callback)
  local script = [[
    tell application "Music"
      if player state is not stopped then
        set t to current track
        if (count of artworks of t) > 0 then
          set artData to raw data of artwork 1 of t
          set artFormat to format of artwork 1 of t
          set tempFile to "/tmp/apple-music-artwork.jpg"

          try
            set fileRef to open for access tempFile with write permission
            set eof fileRef to 0
            write artData to fileRef
            close access fileRef
            return tempFile & tab & artFormat
          on error errMsg
            try
              close access tempFile
            end try
            return "error" & tab & errMsg
          end try
        else
          return "noartwork" & tab & ""
        end if
      else
        return "stopped" & tab & ""
      end if
    end tell
  ]]

  execute_applescript_async(script, function(result, err)
    if err or not result then
      callback(nil, err)
      return
    end

    local parts = vim.split(result, '\t')
    local status = parts[1]

    if status == 'error' or status == 'noartwork' or status == 'stopped' then
      callback(nil, parts[2])
    else
      -- Success - parts[1] is file path, parts[2] is format
      callback({ path = parts[1], format = parts[2] })
    end
  end)
end

function M.play_pause()
  execute_applescript('tell application "Music" to playpause')
end

function M.next_track()
  execute_applescript('tell application "Music" to next track')
end

function M.previous_track()
  execute_applescript('tell application "Music" to previous track')
end

function M.set_volume(volume)
  execute_applescript(string.format('tell application "Music" to set sound volume to %d', volume))
end

function M.increase_volume()
  -- Use cached volume from UI state instead of querying
  local ui = require('apple-music.ui')
  if ui.last_state and ui.last_state.volume then
    M.set_volume(math.min(100, ui.last_state.volume + 10))
  end
end

function M.decrease_volume()
  local ui = require('apple-music.ui')
  if ui.last_state and ui.last_state.volume then
    M.set_volume(math.max(0, ui.last_state.volume - 10))
  end
end

function M.toggle_shuffle()
  execute_applescript([[
    tell application "Music"
      set shuffle enabled to not shuffle enabled
    end tell
  ]])
end

function M.set_position(position)
  execute_applescript(string.format('tell application "Music" to set player position to %f', position))
end

function M.seek_forward(seconds)
  -- Use cached position from UI state instead of querying
  local ui = require('apple-music.ui')
  if ui.last_state and ui.last_state.position and ui.last_state.duration then
    local new_position = math.min(ui.last_state.duration, ui.last_state.position + seconds)
    M.set_position(new_position)
  end
end

function M.seek_backward(seconds)
  local ui = require('apple-music.ui')
  if ui.last_state and ui.last_state.position then
    local new_position = math.max(0, ui.last_state.position - seconds)
    M.set_position(new_position)
  end
end

return M
