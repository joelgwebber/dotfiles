return {
  'leoluz/nvim-dap-go',

  dependencies = {
    'mfussenegger/nvim-dap',
    'rcarriga/nvim-dap-ui',
  },

  config = function()
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
