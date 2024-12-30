return {
  'mfussenegger/nvim-dap',

  dependencies = {
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
    'rcarriga/nvim-dap-ui',
  },

  config = function()
    require('dap-python').setup 'python'
    require('dap-go').setup {}
    -- require('dap.ext.vscode').load_launchjs(nil)
    require('dap').configurations.python = {
      {
        type = 'python',
        name = 'python file',
        request = 'launch',
        program = '${file}',
        console = 'integratedTerminal',
        cwd = vim.fn.getcwd(),
      },
    }
    require('dapui').setup {}
  end,
}
