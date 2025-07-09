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
}
