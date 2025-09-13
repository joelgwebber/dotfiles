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
    require('mini.move').setup {
      mappings = {
        -- Move visual selection in Visual mode. Defaults are Alt (Meta) + hjkl.
        left = '<C-S-h>',
        right = '<C-S-l>',
        down = '<C-S-j>',
        up = '<C-S-k>',

        -- Move current line in Normal mode
        line_left = '<C-S-h>',
        line_right = '<C-S-l>',
        line_down = '<C-S-j>',
        line_up = '<C-S-k>',
      },

      options = {
        reindent_linewise = true,
      },
    }

    require('mini.files').setup {
      windows = {
        preview = true,
        width_preview = 50,
      },
      options = {
        use_as_default_explorer = true,
        permanent_delete = false, -- Use trash instead of permanent delete
      },
      mappings = {
        close = 'q',
        go_in = 'l',
        go_in_plus = '<CR>',
        go_out = 'h',
        go_out_plus = '-',
        reset = '<BS>',
        reveal_cwd = '@',
        show_help = 'g?',
        synchronize = '=',
        trim_left = '<',
        trim_right = '>',
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
