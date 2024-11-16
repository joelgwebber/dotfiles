return {
  'leoluz/nvim-dap-go',

  dependencies = {
    'mfussenegger/nvim-dap',
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
  end,
}
