return {
  'mfussenegger/nvim-dap',

  dependencies = {
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python',
    'rcarriga/nvim-dap-ui',
  },

  config = function()
    require('dap-python').setup 'python'
    require('dap-go').setup {
      dap_configurations = {
        {
          type = 'go',
          name = 'attach remote',
          mode = 'remote',
          request = 'attach',
        },
      },
    }
    require('dapui').setup {
      -- ...
    }
  end,
}
