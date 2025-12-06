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
}
