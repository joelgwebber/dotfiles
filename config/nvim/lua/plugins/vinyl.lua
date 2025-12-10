return {
  dir = vim.fn.expand '~/src/vinyl.nvim',
  name = 'vinyl.nvim',

  config = function()
    require('vinyl').setup {
      update_interval = 1000,
      window = {
        width = 36,
      },
      artwork = {
        enabled = true, -- Enabled with docked window (more stable than floating)
        max_width_chars = 40, -- Maximum width in character cells
        max_height_chars = 20, -- Maximum height in character cells (half of width for square aspect ratio)
      },
    }
  end,
}
