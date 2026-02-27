return {
  'wojciech-kulik/xcodebuild.nvim',

  dependencies = {
    'nvim-telescope/telescope.nvim',
    'MunifTanjim/nui.nvim',
    'nvim-treesitter/nvim-treesitter',
  },

  ft = 'swift',
  cmd = {
    'XcodebuildSetup',
    'XcodebuildPicker',
    'XcodebuildBuild',
    'XcodebuildBuildRun',
    'XcodebuildBuildForTesting',
    'XcodebuildTest',
    'XcodebuildTestClass',
    'XcodebuildRun',
    'XcodebuildDebug',
    'XcodebuildSelectDevice',
    'XcodebuildSelectScheme',
  },

  keys = {
    { '<leader>X', '<cmd>XcodebuildPicker<cr>', desc = 'Xcodebuild Actions' },
    { '<leader>xf', '<cmd>XcodebuildProjectManager<cr>', desc = 'Project Manager' },

    { '<leader>xb', '<cmd>XcodebuildBuild<cr>', desc = 'Build Project' },
    { '<leader>xB', '<cmd>XcodebuildBuildForTesting<cr>', desc = 'Build For Testing' },
    { '<leader>xr', '<cmd>XcodebuildBuildRun<cr>', desc = 'Build & Run' },
    { '<leader>xR', '<cmd>XcodebuildRun<cr>', desc = 'Run Without Building' },

    { '<leader>xt', '<cmd>XcodebuildTest<cr>', desc = 'Run Tests' },
    { '<leader>xT', '<cmd>XcodebuildTestClass<cr>', desc = 'Run Test Class' },
    { '<leader>xt', '<cmd>XcodebuildTestSelected<cr>', desc = 'Run Selected Tests', mode = 'v' },
    { '<leader>x.', '<cmd>XcodebuildTestRepeat<cr>', desc = 'Repeat Last Test' },

    { '<leader>xl', '<cmd>XcodebuildToggleLogs<cr>', desc = 'Toggle Logs' },
    { '<leader>xc', '<cmd>XcodebuildToggleCodeCoverage<cr>', desc = 'Toggle Code Coverage' },
    { '<leader>xC', '<cmd>XcodebuildShowCodeCoverageReport<cr>', desc = 'Coverage Report' },
    { '<leader>xe', '<cmd>XcodebuildTestExplorerToggle<cr>', desc = 'Toggle Test Explorer' },

    { '<leader>xp', '<cmd>XcodebuildPreviewGenerateAndShow<cr>', desc = 'Generate Preview' },
    { '<leader>x<cr>', '<cmd>XcodebuildPreviewToggle<cr>', desc = 'Toggle Preview' },

    { '<leader>xd', '<cmd>XcodebuildSelectDevice<cr>', desc = 'Select Device' },
    { '<leader>xs', '<cmd>XcodebuildSelectScheme<cr>', desc = 'Select Scheme' },
    { '<leader>xx', '<cmd>XcodebuildQuickfixLine<cr>', desc = 'Quickfix Line' },
    { '<leader>xa', '<cmd>XcodebuildCodeActions<cr>', desc = 'Code Actions' },
  },

  config = function()
    require('xcodebuild').setup {
      show_build_progress_bar = true,
      logs = {
        auto_open_on_success_build = false,
        auto_open_on_failed_build = true,
        auto_close_on_app_launch = true,
      },
    }

    -- DAP integration via codelldb (installed by Mason)
    local codelldb_path = vim.fn.stdpath 'data' .. '/mason/bin/codelldb'
    if vim.fn.executable(codelldb_path) == 1 then
      require('xcodebuild.integrations.dap').setup(codelldb_path)

      vim.keymap.set('n', '<leader>dd', require('xcodebuild.integrations.dap').build_and_debug, { desc = 'Build & Debug' })
      vim.keymap.set('n', '<leader>dr', require('xcodebuild.integrations.dap').debug_without_build, { desc = 'Debug Without Building' })
      vim.keymap.set('n', '<leader>dt', require('xcodebuild.integrations.dap').debug_tests, { desc = 'Debug Tests' })
      vim.keymap.set('n', '<leader>dT', require('xcodebuild.integrations.dap').debug_class_tests, { desc = 'Debug Class Tests' })
      vim.keymap.set('n', '<leader>dx', require('xcodebuild.integrations.dap').terminate_session, { desc = 'Terminate Debug Session' })
    end
  end,
}
