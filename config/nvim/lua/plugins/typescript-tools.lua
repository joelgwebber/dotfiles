return {
  'pmizio/typescript-tools.nvim',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  config = function()
    require('typescript-tools').setup {
      settings = {
        tsserver_max_memory = 8192,
        tsserver_file_preferences = {
          includeCompletionsForModuleExports = true,
        },
      },
    }
  end,
}
