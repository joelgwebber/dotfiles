-- Vim commands for apple-music.nvim

-- Subcommand handlers
local subcommands = {
  -- Main UI
  toggle = function()
    require('apple-music').toggle_ui()
  end,

  -- Playback controls
  play = function()
    require('apple-music').play_pause()
  end,
  pause = function()
    require('apple-music').play_pause()
  end,
  next = function()
    require('apple-music').next_track()
  end,
  prev = function()
    require('apple-music').previous_track()
  end,
  shuffle = function()
    require('apple-music').toggle_shuffle()
  end,

  -- Library browsing
  playlists = function()
    require('apple-music').browse_playlists()
  end,
  albums = function()
    require('apple-music').browse_albums()
  end,
  tracks = function()
    require('apple-music').browse_tracks()
  end,
  artists = function()
    require('apple-music').browse_artists()
  end,

  -- Backend management
  backend = function(args)
    local backend_name = args[1]
    if not backend_name then
      -- Show current backend and available backends
      local current = require('apple-music').get_backend()
      if current then
        print('Current backend: ' .. current.display_name)
      else
        print('No backend active')
      end
      print('Available: apple_music, spotify')
    else
      require('apple-music').use_backend(backend_name)
    end
  end,

  -- Spotify-specific
  ['spotify-login'] = function()
    require('apple-music').spotify_login()
  end,
  ['spotify-logout'] = function()
    require('apple-music').spotify_logout()
  end,
  ['spotify-status'] = function()
    require('apple-music').spotify_status()
  end,

  -- Debug
  ['debug-backend'] = function()
    require('apple-music').debug_backend()
  end,
  ['debug-queue'] = function()
    require('apple-music').debug_queue()
  end,
}

-- Main :Vinyl command with subcommand completion
vim.api.nvim_create_user_command('Vinyl', function(opts)
  local args = vim.split(opts.args, '%s+')
  local subcmd = args[1]

  if not subcmd or subcmd == '' then
    subcmd = 'toggle'
  end

  local handler = subcommands[subcmd]
  if handler then
    -- Pass remaining args to handler
    local subcmd_args = vim.list_slice(args, 2)
    handler(subcmd_args)
  else
    vim.notify('Unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
    vim.notify('Available: ' .. table.concat(vim.tbl_keys(subcommands), ', '), vim.log.levels.INFO)
  end
end, {
  nargs = '*',
  complete = function(arg_lead, cmd_line, cursor_pos)
    -- Get all typed arguments
    local args = vim.split(cmd_line, '%s+')

    -- If we're still on first arg (subcommand), complete subcommands
    if #args <= 2 then
      local matches = {}
      for name, _ in pairs(subcommands) do
        if vim.startswith(name, arg_lead) then
          table.insert(matches, name)
        end
      end
      table.sort(matches)
      return matches
    end

    -- If subcommand is 'backend', complete backend names
    if args[2] == 'backend' then
      local backends = { 'apple_music', 'spotify' }
      local matches = {}
      for _, name in ipairs(backends) do
        if vim.startswith(name, arg_lead) then
          table.insert(matches, name)
        end
      end
      return matches
    end

    return {}
  end,
  desc = 'Music player control'
})
