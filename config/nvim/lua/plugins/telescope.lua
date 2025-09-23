return { -- Fuzzy Finder (files, lsp, etc)
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  branch = '0.1.x',

  dependencies = {
    { 'nvim-lua/plenary.nvim' },
    { -- If encountering errors, see telescope-fzf-native README for installation instructions
      'nvim-telescope/telescope-fzf-native.nvim',
      'nvim-telescope/telescope-live-grep-args.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local telescope = require 'telescope'

    telescope.setup {
      defaults = {
        -- Use default telescope borders
        prompt_prefix = ' ',
        selection_caret = '▌ ',
        layout_config = {
          prompt_position = 'bottom',
        },
      },

      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown {},
        },
      },

      pickers = {
        -- Customize buffer list to show all, allow deletion.
        buffers = {
          show_all_buffers = true,
          sort_mru = true,
          mappings = {
            n = {
              ['d'] = 'delete_buffer',
              ['D'] = 'delete_buffer', -- TODO: Make this db! somehow
            },
          },
        },
      },
    }

    telescope.load_extension 'live_grep_args'

    -- Enable Telescope extensions if they are installed
    pcall(require('telescope').load_extension, 'fzf')
    pcall(require('telescope').load_extension, 'ui-select')
  end,
}
