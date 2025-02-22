-- Install lazy plugin manager
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

-- Vim options
require 'config.options'

-- Lazy setup
require('lazy').setup {
  'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
  'numToStr/Comment.nvim', -- Comment/todo management
  'monaqa/dial.nvim', -- Number twiddling
  'stevearc/stickybuf.nvim', -- Pin buffers to windows

  { -- Nicer color scheme
    'folke/tokyonight.nvim',
    priority = 1000, -- Make sure to load this before all the other start plugins.
    opts = {
      style = 'night',
      terminal_colors = true,
      styles = {
        comments = { italic = true },
      },
    },
  },

  { -- Setup global which-key binding structure.
    'folke/which-key.nvim',
    event = 'VimEnter',
    config = function()
      require('which-key').setup()
    end,
  },

  { -- Diagnostics
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      use_diagnostic_signs = true,
      -- TODO: Turn off peek/refresh by default;
      -- bind to buffer it was opened from;
      -- auto-focus on open
    },
  },

  { -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },

  { -- REPL
    'milanglacier/yarepl.nvim',
    config = function(_, _)
      local yarepl = require 'yarepl'
      yarepl.setup {
        metas = {
          sardine = { cmd = 'sardine', formatter = yarepl.formatter.bracketed_pasting },
        },
      }
    end,
  },

  { -- Lazy Git
    'kdheepak/lazygit.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
    },
  },

  { -- Inline git blame
    'f-person/git-blame.nvim', -- Git blame overlay
    opts = {
      enabled = false,
      virtual_text_column = 80,
    },
    config = function(_, opts)
      require('gitblame').setup(opts)
    end,
  },

  { -- Unit testing
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
        summary = { animated = false },
        adapters = {
          require 'neotest-python' {
            -- runner = 'pytest',
          },
          require 'neotest-golang' {
            -- recursive_run = true,
          },
        },
      }
    end,
  },

  {
    'davidgranstrom/scnvim',
    config = function(_, opts)
      local sc = require 'scnvim'
      local map = sc.map
      require('scnvim').setup {
        -- Keep these keymaps local to .sc[d] files (i.e., not in keymaps.lua).
        keymaps = {
          ['<CR>'] = {
            map('editor.send_block', { 'n' }),
            map('editor.send_selection', { 'x' }),
          },
          ['<D-CR>'] = map('postwin.toggle', { 'n', 'i' }),
          ['<C-CR>'] = map('postwin.toggle', { 'n', 'i' }),
          ['<D-S-L>'] = map('postwin.clear', { 'n', 'i' }),
          ['<A-S-L>'] = map('postwin.clear', { 'n', 'i' }),
          ['<D-space>'] = map('signature.show', { 'n', 'i' }),
          ['<A-space>'] = map('signature.show', { 'n', 'i' }),
        },
      }
    end,
  },

  {
    'ray-x/go.nvim',
    dependencies = { -- optional packages
      'ray-x/guihua.lua',
      'neovim/nvim-lspconfig',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('go').setup()
      -- if you need to install/update all binaries
      -- local build = ':lua require("go.install").update_all_sync()'
    end,
    event = { 'CmdlineEnter' },
    ft = { 'go', 'gomod' },
  },

  { 'gennaro-tedesco/nvim-jqx', event = { 'BufReadPost' }, ft = { 'json', 'yaml' } },

  {
    'marcussimonsen/let-it-snow.nvim',
    cmd = 'LetItSnow', -- Wait with loading until command is run
    opts = {},
  },

  -- Other plugins with more configuration
  { import = 'plugins' },

  -- Disabled because I've mostly found it distracting, and don't use it much
  -- because it makes me more error-prone when searching.
  -- { -- Flash movement
  --   'folke/flash.nvim',
  --   event = 'VeryLazy',
  --
  --   config = function(_, _)
  --     require('flash').setup {
  --       label = {
  --         rainbow = {
  --           enabled = true,
  --           shade = 9,
  --         },
  --       },
  --       modes = {
  --         search = {
  --           enabled = true,
  --         },
  --       },
  --     }
  --   end,
  -- },
}

require 'config.keymaps' -- Global key mappings
require 'config.autocmds' -- Autocommands

vim.cmd 'colorscheme j15r'
