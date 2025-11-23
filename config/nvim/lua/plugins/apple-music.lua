return {
  dir = vim.fn.expand '~/dotfiles/plugins/apple-music.nvim',
  name = 'apple-music.nvim',
  -- No dependencies - we implement Kitty graphics protocol directly!
  config = function()
    require('apple-music').setup {
      update_interval = 2000,
      window = {
        width = 48,
      },
      artwork = {
        enabled = true, -- Enabled with docked window (more stable than floating)
        max_width_chars = 40, -- Maximum width in character cells
        max_height_chars = 20, -- Maximum height in character cells (half of width for square aspect ratio)
      },
    }
  end,
  keys = {
    -- UI
    {
      '<leader>mu',
      function()
        require('apple-music').toggle_ui()
      end,
      desc = 'Toggle [u]i',
    },

    -- Playback controls
    {
      '<leader>mp',
      function()
        require('apple-music').play_pause()
      end,
      desc = 'Toggle [p]lay/pause',
    },
    {
      '<leader>mn',
      function()
        require('apple-music').next_track()
      end,
      desc = '[n]ext track',
    },
    {
      '<leader>mN',
      function()
        require('apple-music').previous_track()
      end,
      desc = 'Previous track',
    },
    {
      '<leader>ms',
      function()
        require('apple-music').toggle_shuffle()
      end,
      desc = 'Toggle [s]huffle',
    },

    -- Volume
    {
      '<leader>m=',
      function()
        require('apple-music').increase_volume()
      end,
      desc = 'Volume up',
    },
    {
      '<leader>m-',
      function()
        require('apple-music').decrease_volume()
      end,
      desc = 'Volume down',
    },
  },
}
