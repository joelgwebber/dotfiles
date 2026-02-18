return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false,
  build = ':TSUpdate',

  config = function()
    require('nvim-treesitter').setup()

    -- Install parsers if missing
    require('nvim-treesitter').install {
      'bash', 'c', 'diff', 'gitcommit', 'html', 'lua', 'luadoc',
      'markdown', 'swift', 'vim', 'vimdoc',
    }

    -- Enable treesitter highlighting and indentation for all filetypes
    vim.api.nvim_create_autocmd('FileType', {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,

  dependencies = {
    {
      'nvim-treesitter/nvim-treesitter-context', -- Nice stacking code context
      opts = {
        enable = true,
        max_lines = 3,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = 'outer',
        mode = 'cursor',
        separator = nil,
        zindex = 20,
        on_attach = nil,
      },
    },
  },
}
