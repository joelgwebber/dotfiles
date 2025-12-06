-- Library search and browsing functionality
local M = {}

-- Check for available pickers in order of preference
local function get_picker()
  local has_telescope, telescope = pcall(require, 'telescope.builtin')
  if has_telescope then
    return 'telescope', telescope
  end

  local has_fzf, fzf = pcall(require, 'fzf-lua')
  if has_fzf then
    return 'fzf-lua', fzf
  end

  return 'vim.ui.select', nil
end

-- Generic picker function that works with any item list
-- Items should have { id, name, artist?, album? }
function M.show_picker(items, title, on_select)
  local picker_type, picker = get_picker()

  if picker_type == 'telescope' then
    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    pickers.new({}, {
      prompt_title = title,
      finder = finders.new_table({
        results = items,
        entry_maker = function(entry)
          local display_text = entry.name
          if entry.artist then
            display_text = string.format("%s - %s", entry.name, entry.artist)
          end
          if entry.album then
            display_text = display_text .. string.format(" [%s]", entry.album)
          end

          return {
            value = entry,
            display = display_text,
            ordinal = entry.name .. ' ' .. (entry.artist or '') .. ' ' .. (entry.album or ''),
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection then
            on_select(selection.value)
          end
        end)
        return true
      end,
    }):find()
  elseif picker_type == 'fzf-lua' then
    local fzf = require('fzf-lua')
    local entries = {}
    for _, item in ipairs(items) do
      local display_text = item.name
      if item.artist then
        display_text = string.format("%s - %s", item.name, item.artist)
      end
      if item.album then
        display_text = display_text .. string.format(" [%s]", item.album)
      end
      table.insert(entries, display_text)
    end

    fzf.fzf_exec(entries, {
      prompt = title .. '> ',
      actions = {
        ['default'] = function(selected)
          if selected and #selected > 0 then
            -- Find the item by matching the display text
            local selected_text = selected[1]
            for _, item in ipairs(items) do
              local display_text = item.name
              if item.artist then
                display_text = string.format("%s - %s", item.name, item.artist)
              end
              if item.album then
                display_text = display_text .. string.format(" [%s]", item.album)
              end
              if display_text == selected_text then
                on_select(item)
                break
              end
            end
          end
        end,
      },
    })
  else
    -- vim.ui.select fallback
    local display_items = {}
    for _, item in ipairs(items) do
      local display_text = item.name
      if item.artist then
        display_text = string.format("%s - %s", item.name, item.artist)
      end
      if item.album then
        display_text = display_text .. string.format(" [%s]", item.album)
      end
      table.insert(display_items, display_text)
    end

    vim.ui.select(display_items, {
      prompt = title .. ':',
    }, function(choice, idx)
      if idx then
        on_select(items[idx])
      end
    end)
  end
end

-- Get all tracks from library
-- Returns: { { name, artist, album, persistent_id }, ... }
function M.get_library_tracks_async(callback)
  local script = [[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib
      set output to ""

      repeat with t in allTracks
        try
          set output to output & (name of t) & tab
          set output to output & (artist of t) & tab
          set output to output & (album of t) & tab
          set output to output & (persistent ID of t) & linefeed
        end try
      end repeat

      return output
    end tell
  ]]

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 or not result.stdout then
        callback(nil, "Failed to fetch library tracks")
        return
      end

      local tracks = {}
      for line in result.stdout:gmatch("[^\n]+") do
        local parts = {}
        for part in line:gmatch("[^\t]+") do
          table.insert(parts, part)
        end

        if #parts >= 4 then
          table.insert(tracks, {
            name = parts[1],
            artist = parts[2],
            album = parts[3],
            persistent_id = parts[4],
          })
        end
      end

      callback(tracks, nil)
    end)
  )
end

-- Get all albums from library (unique album names)
-- Returns: { { album, artist }, ... }
function M.get_library_albums_async(callback)
  local script = [[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib
      set albumSet to {}
      set output to ""

      repeat with t in allTracks
        try
          set albumName to album of t
          set artistName to artist of t
          set albumKey to albumName & "|||" & artistName

          if albumSet does not contain albumKey then
            set end of albumSet to albumKey
            set output to output & albumName & tab & artistName & linefeed
          end if
        end try
      end repeat

      return output
    end tell
  ]]

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 or not result.stdout then
        callback(nil, "Failed to fetch library albums")
        return
      end

      local albums = {}
      for line in result.stdout:gmatch("[^\n]+") do
        local parts = {}
        for part in line:gmatch("[^\t]+") do
          table.insert(parts, part)
        end

        if #parts >= 2 then
          table.insert(albums, {
            album = parts[1],
            artist = parts[2],
          })
        end
      end

      callback(albums, nil)
    end)
  )
end

-- Get all artists from library (unique artist names)
-- Returns: { "Artist Name", ... }
function M.get_library_artists_async(callback)
  local script = [[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib
      set artistSet to {}
      set output to ""

      repeat with t in allTracks
        try
          set artistName to artist of t

          if artistSet does not contain artistName then
            set end of artistSet to artistName
            set output to output & artistName & linefeed
          end if
        end try
      end repeat

      return output
    end tell
  ]]

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 or not result.stdout then
        callback(nil, "Failed to fetch library artists")
        return
      end

      local artists = {}
      for line in result.stdout:gmatch("[^\n]+") do
        if line ~= "" then
          table.insert(artists, line)
        end
      end

      callback(artists, nil)
    end)
  )
end

-- Get all playlists
-- Returns: { { name, persistent_id }, ... }
function M.get_playlists_async(callback)
  local script = [[
    tell application "Music"
      set allPlaylists to user playlists
      set output to ""

      repeat with p in allPlaylists
        try
          set output to output & (name of p) & tab
          set output to output & (persistent ID of p) & linefeed
        end try
      end repeat

      return output
    end tell
  ]]

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 or not result.stdout then
        callback(nil, "Failed to fetch playlists")
        return
      end

      local playlists = {}
      for line in result.stdout:gmatch("[^\n]+") do
        local parts = {}
        for part in line:gmatch("[^\t]+") do
          table.insert(parts, part)
        end

        if #parts >= 2 then
          table.insert(playlists, {
            name = parts[1],
            persistent_id = parts[2],
          })
        end
      end

      callback(playlists, nil)
    end)
  )
end

-- Play a track by persistent ID
function M.play_track(persistent_id, callback)
  local script = string.format([[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib

      repeat with t in allTracks
        if persistent ID of t is "%s" then
          play t
          return "OK"
        end if
      end repeat

      return "Track not found"
    end tell
  ]], persistent_id)

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if callback then
        callback(result.code == 0, result.stdout)
      end
    end)
  )
end

-- Play an album (all tracks from that album/artist combination)
function M.play_album(album, artist, callback)
  local script = string.format([[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib
      set albumTracks to {}

      repeat with t in allTracks
        if album of t = "%s" and artist of t = "%s" then
          set end of albumTracks to t
        end if
      end repeat

      if (count of albumTracks) > 0 then
        -- Clear the current queue and play the album
        set shuffle enabled to false
        play item 1 of albumTracks

        -- Add remaining tracks to up next queue
        repeat with i from 2 to (count of albumTracks)
          set theTrack to item i of albumTracks
          -- This ensures the full album plays in order
        end repeat

        return "OK"
      else
        return "Album not found"
      end if
    end tell
  ]], album:gsub('"', '\\"'), artist:gsub('"', '\\"'))

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if callback then
        callback(result.code == 0, result.stdout)
      end
    end)
  )
end

-- Play tracks by an artist (shuffled, like Apple Music's default artist play)
function M.play_artist(artist, callback)
  local script = string.format([[
    tell application "Music"
      set lib to library playlist 1
      set allTracks to every track of lib
      set artistTracks to {}

      repeat with t in allTracks
        if artist of t = "%s" then
          set end of artistTracks to t
        end if
      end repeat

      if (count of artistTracks) > 0 then
        -- Enable shuffle and play the first track
        -- Apple Music will continue shuffling through the artist's tracks
        set shuffle enabled to true
        play item 1 of artistTracks
        return "OK"
      else
        return "Artist not found"
      end if
    end tell
  ]], artist:gsub('"', '\\"'))

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if callback then
        callback(result.code == 0, result.stdout)
      end
    end)
  )
end

-- Play a playlist by persistent ID
function M.play_playlist(persistent_id, callback)
  local script = string.format([[
    tell application "Music"
      set allPlaylists to user playlists

      repeat with p in allPlaylists
        if persistent ID of p is "%s" then
          play p
          return "OK"
        end if
      end repeat

      return "Playlist not found"
    end tell
  ]], persistent_id)

  vim.system(
    { 'osascript', '-e', script },
    { text = true },
    vim.schedule_wrap(function(result)
      if callback then
        callback(result.code == 0, result.stdout)
      end
    end)
  )
end

-- Telescope picker for tracks
function M.browse_tracks()
  local picker_type, picker = get_picker()

  M.get_library_tracks_async(function(tracks, err)
    if err or not tracks then
      vim.notify("Failed to fetch tracks: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #tracks == 0 then
      vim.notify("No tracks found in library", vim.log.levels.WARN)
      return
    end

    if picker_type == 'telescope' then
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      pickers.new({}, {
        prompt_title = 'Apple Music - Tracks',
        finder = finders.new_table({
          results = tracks,
          entry_maker = function(entry)
            return {
              value = entry,
              display = string.format("%-40s  %s  [%s]",
                entry.name:sub(1, 40),
                entry.artist:sub(1, 30),
                entry.album:sub(1, 30)
              ),
              ordinal = entry.name .. ' ' .. entry.artist .. ' ' .. entry.album,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              M.play_track(selection.value.persistent_id, function(success, msg)
                if success then
                  vim.notify("Playing: " .. selection.value.name, vim.log.levels.INFO)
                else
                  vim.notify("Failed to play track: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                end
              end)
            end
          end)
          return true
        end,
      }):find()

    elseif picker_type == 'fzf-lua' then
      local items = {}
      for _, track in ipairs(tracks) do
        table.insert(items, string.format("%-40s  %s  [%s]",
          track.name:sub(1, 40),
          track.artist:sub(1, 30),
          track.album:sub(1, 30)
        ))
      end

      picker.fzf_exec(items, {
        prompt = 'Apple Music - Tracks> ',
        actions = {
          ['default'] = function(selected)
            if selected and #selected > 0 then
              local idx = nil
              for i, item in ipairs(items) do
                if item == selected[1] then
                  idx = i
                  break
                end
              end

              if idx and tracks[idx] then
                M.play_track(tracks[idx].persistent_id, function(success, msg)
                  if success then
                    vim.notify("Playing: " .. tracks[idx].name, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to play track: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                  end
                end)
              end
            end
          end,
        },
      })

    else
      -- vim.ui.select fallback
      local items = {}
      for _, track in ipairs(tracks) do
        table.insert(items, string.format("%s - %s (%s)",
          track.name,
          track.artist,
          track.album
        ))
      end

      vim.ui.select(items, {
        prompt = 'Select track to play:',
      }, function(choice, idx)
        if idx and tracks[idx] then
          M.play_track(tracks[idx].persistent_id, function(success, msg)
            if success then
              vim.notify("Playing: " .. tracks[idx].name, vim.log.levels.INFO)
            else
              vim.notify("Failed to play track: " .. (msg or "unknown error"), vim.log.levels.ERROR)
            end
          end)
        end
      end)
    end
  end)
end

-- Telescope picker for albums
function M.browse_albums()
  local picker_type, picker = get_picker()

  M.get_library_albums_async(function(albums, err)
    if err or not albums then
      vim.notify("Failed to fetch albums: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #albums == 0 then
      vim.notify("No albums found in library", vim.log.levels.WARN)
      return
    end

    if picker_type == 'telescope' then
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      pickers.new({}, {
        prompt_title = 'Apple Music - Albums',
        finder = finders.new_table({
          results = albums,
          entry_maker = function(entry)
            return {
              value = entry,
              display = string.format("%-50s  %s",
                entry.album:sub(1, 50),
                entry.artist:sub(1, 30)
              ),
              ordinal = entry.album .. ' ' .. entry.artist,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              M.play_album(selection.value.album, selection.value.artist, function(success, msg)
                if success then
                  vim.notify("Playing album: " .. selection.value.album, vim.log.levels.INFO)
                else
                  vim.notify("Failed to play album: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                end
              end)
            end
          end)
          return true
        end,
      }):find()

    elseif picker_type == 'fzf-lua' then
      local items = {}
      for _, album in ipairs(albums) do
        table.insert(items, string.format("%-50s  %s",
          album.album:sub(1, 50),
          album.artist:sub(1, 30)
        ))
      end

      picker.fzf_exec(items, {
        prompt = 'Apple Music - Albums> ',
        actions = {
          ['default'] = function(selected)
            if selected and #selected > 0 then
              local idx = nil
              for i, item in ipairs(items) do
                if item == selected[1] then
                  idx = i
                  break
                end
              end

              if idx and albums[idx] then
                M.play_album(albums[idx].album, albums[idx].artist, function(success, msg)
                  if success then
                    vim.notify("Playing album: " .. albums[idx].album, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to play album: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                  end
                end)
              end
            end
          end,
        },
      })

    else
      -- vim.ui.select fallback
      local items = {}
      for _, album in ipairs(albums) do
        table.insert(items, string.format("%s - %s",
          album.album,
          album.artist
        ))
      end

      vim.ui.select(items, {
        prompt = 'Select album to play:',
      }, function(choice, idx)
        if idx and albums[idx] then
          M.play_album(albums[idx].album, albums[idx].artist, function(success, msg)
            if success then
              vim.notify("Playing album: " .. albums[idx].album, vim.log.levels.INFO)
            else
              vim.notify("Failed to play album: " .. (msg or "unknown error"), vim.log.levels.ERROR)
            end
          end)
        end
      end)
    end
  end)
end

-- Telescope picker for artists
function M.browse_artists()
  local picker_type, picker = get_picker()

  M.get_library_artists_async(function(artists, err)
    if err or not artists then
      vim.notify("Failed to fetch artists: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #artists == 0 then
      vim.notify("No artists found in library", vim.log.levels.WARN)
      return
    end

    if picker_type == 'telescope' then
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      pickers.new({}, {
        prompt_title = 'Apple Music - Artists',
        finder = finders.new_table({
          results = artists,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              M.play_artist(selection.value, function(success, msg)
                if success then
                  vim.notify("Playing artist: " .. selection.value, vim.log.levels.INFO)
                else
                  vim.notify("Failed to play artist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                end
              end)
            end
          end)
          return true
        end,
      }):find()

    elseif picker_type == 'fzf-lua' then
      picker.fzf_exec(artists, {
        prompt = 'Apple Music - Artists> ',
        actions = {
          ['default'] = function(selected)
            if selected and #selected > 0 then
              M.play_artist(selected[1], function(success, msg)
                if success then
                  vim.notify("Playing artist: " .. selected[1], vim.log.levels.INFO)
                else
                  vim.notify("Failed to play artist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                end
              end)
            end
          end,
        },
      })

    else
      -- vim.ui.select fallback
      vim.ui.select(artists, {
        prompt = 'Select artist to play:',
      }, function(choice, idx)
        if choice then
          M.play_artist(choice, function(success, msg)
            if success then
              vim.notify("Playing artist: " .. choice, vim.log.levels.INFO)
            else
              vim.notify("Failed to play artist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
            end
          end)
        end
      end)
    end
  end)
end

-- Telescope picker for playlists
function M.browse_playlists()
  local picker_type, picker = get_picker()

  M.get_playlists_async(function(playlists, err)
    if err or not playlists then
      vim.notify("Failed to fetch playlists: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    if #playlists == 0 then
      vim.notify("No playlists found in library", vim.log.levels.WARN)
      return
    end

    if picker_type == 'telescope' then
      local pickers = require('telescope.pickers')
      local finders = require('telescope.finders')
      local conf = require('telescope.config').values
      local actions = require('telescope.actions')
      local action_state = require('telescope.actions.state')

      pickers.new({}, {
        prompt_title = 'Apple Music - Playlists',
        finder = finders.new_table({
          results = playlists,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.name,
              ordinal = entry.name,
            }
          end,
        }),
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)

            if selection then
              M.play_playlist(selection.value.persistent_id, function(success, msg)
                if success then
                  vim.notify("Playing playlist: " .. selection.value.name, vim.log.levels.INFO)
                else
                  vim.notify("Failed to play playlist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                end
              end)
            end
          end)
          return true
        end,
      }):find()

    elseif picker_type == 'fzf-lua' then
      local items = {}
      for _, playlist in ipairs(playlists) do
        table.insert(items, playlist.name)
      end

      picker.fzf_exec(items, {
        prompt = 'Apple Music - Playlists> ',
        actions = {
          ['default'] = function(selected)
            if selected and #selected > 0 then
              local idx = nil
              for i, item in ipairs(items) do
                if item == selected[1] then
                  idx = i
                  break
                end
              end

              if idx and playlists[idx] then
                M.play_playlist(playlists[idx].persistent_id, function(success, msg)
                  if success then
                    vim.notify("Playing playlist: " .. playlists[idx].name, vim.log.levels.INFO)
                  else
                    vim.notify("Failed to play playlist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
                  end
                end)
              end
            end
          end,
        },
      })

    else
      -- vim.ui.select fallback
      local items = {}
      for _, playlist in ipairs(playlists) do
        table.insert(items, playlist.name)
      end

      vim.ui.select(items, {
        prompt = 'Select playlist to play:',
      }, function(choice, idx)
        if idx and playlists[idx] then
          M.play_playlist(playlists[idx].persistent_id, function(success, msg)
            if success then
              vim.notify("Playing playlist: " .. playlists[idx].name, vim.log.levels.INFO)
            else
              vim.notify("Failed to play playlist: " .. (msg or "unknown error"), vim.log.levels.ERROR)
            end
          end)
        end
      end)
    end
  end)
end

return M
