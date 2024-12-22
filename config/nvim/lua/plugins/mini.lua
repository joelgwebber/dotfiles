return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',

  config = function()
    -- Better Around/Inside textobjects
    require('mini.ai').setup { n_lines = 500 }

    -- Add/delete/replace surroundings (brackets, quotes, etc.)
    require('mini.surround').setup()

    -- Better comments
    require('mini.comment').setup()

    -- Notifications
    require('mini.notify').setup()

    -- Startup UI
    require('mini.starter').setup()

    -- Move selection
    -- TODO: Explore other mappings. This ends up being obtrusive.
    -- require('mini.move').setup {
    --   mappings = {
    --     -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
    --     left = '<A-h>',
    --     right = '<A-l>',
    --     down = '<A-j>',
    --     up = '<A-k>',
    --
    --     -- Move current line in Normal mode
    --     line_left = '<A-h>',
    --     line_right = '<A-l>',
    --     line_down = '<A-j>',
    --     line_up = '<A-k>',
    --   },
    --
    --   options = {
    --     reindent_linewise = true,
    --   },
    -- }

    require('mini.files').setup {
      windows = {
        preview = true,
        width_preview = 50,
      },
    }

    -- Simple and easy statusline.
    local statusline = require 'mini.statusline'
    statusline.setup { use_icons = vim.g.have_nerd_font }

    ---@diagnostic disable-next-line: duplicate-set-field
    statusline.section_location = function()
      return '%2l:%-2v'
    end
  end,
}
