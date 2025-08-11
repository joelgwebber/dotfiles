return {
  'nvim-neotest/neotest',
  dependencies = {
    'nvim-neotest/nvim-nio',
    'nvim-neotest/neotest-python',
    'fredrikaverpil/neotest-golang',
    'nvim-lua/plenary.nvim',
    'antoinemadec/FixCursorHold.nvim',
    'nvim-treesitter/nvim-treesitter',
  },

  config = function(_, opts)
    require('neotest').setup {
      discovery = {
        -- Disable discovery and limit concurrency to avoid runaway processing time for large repos.
        enabled = false,
        -- concurrent = 1,
      },
      running = { concurrent = true },

      output = {
        enabled = true,
        open_on_run = 'short',
      },

      output_panel = {
        enabled = true,
        open = 'botright split | resize 15',
      },

      summary = {
        animated = false,
        count = true,
        enabled = true,
        expand_errors = true,
        follow = true,
        mappings = {
          attach = 'a',
          clear_marked = 'M',
          clear_target = 'T',
          debug = 'd',
          debug_marked = 'D',
          expand = { '<CR>', '<2-LeftMouse>' },
          expand_all = 'e',
          help = '?',
          jumpto = 'i',
          mark = 'm',
          next_failed = 'J',
          output = 'o',
          prev_failed = 'K',
          run = 'r',
          run_marked = 'R',
          short = 'O',
          stop = 'u',
          target = 't',
          watch = 'w',
        },
        open = 'botright vsplit | vertical resize 50',
      },
      adapters = {
        require 'neotest-python' {
          -- runner = 'pytest',
        },
        require 'neotest-golang' {
          -- recursive_run = true,
        },
        -- require 'neotest-rust' {},
      },
    }

    -- Set up autocmds to add 'q' mapping to close neotest windows
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'neotest-summary',
      callback = function(event)
        vim.api.nvim_buf_set_keymap(event.buf, 'n', 'q', '<cmd>lua require("neotest").summary.close()<cr>', {
          noremap = true,
          silent = true,
          desc = 'Close neotest summary',
        })
      end,
    })

    -- For output panel, we need to handle terminal buffers differently
    vim.api.nvim_create_autocmd({ 'BufEnter', 'TermOpen' }, {
      callback = function(event)
        local bufname = vim.api.nvim_buf_get_name(event.buf)
        if bufname:match 'Neotest Output Panel' then
          -- Set filetype for identification
          vim.api.nvim_buf_set_option(event.buf, 'filetype', 'neotest-output')
          -- Map q in normal mode
          vim.api.nvim_buf_set_keymap(event.buf, 'n', 'q', '<cmd>lua require("neotest").output_panel.close()<cr>', {
            noremap = true,
            silent = true,
            desc = 'Close neotest output panel',
          })
          -- Also map q in terminal mode for when you're in terminal insert mode
          vim.api.nvim_buf_set_keymap(event.buf, 't', '<C-\\><C-n>q', '<C-\\><C-n><cmd>lua require("neotest").output_panel.close()<cr>', {
            noremap = true,
            silent = true,
            desc = 'Exit terminal mode and close neotest output panel',
          })
        end
      end,
    })
  end,
}
