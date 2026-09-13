return {
  'mfussenegger/nvim-dap',

  dependencies = {
    'rcarriga/nvim-dap-ui',
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
    'julianolf/nvim-dap-lldb',
  },

  config = function()
    require('dap-python').setup 'python'
    require('dap-go').setup {}
    require('dap-lldb').setup {}

    local dap = require 'dap'
    dap.configurations.python = {
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
