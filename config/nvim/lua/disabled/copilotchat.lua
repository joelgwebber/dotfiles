return {
  'CopilotC-Nvim/CopilotChat.nvim',
  branch = 'main',
  dependencies = {
    { 'zbirenbaum/copilot.lua' },
    { 'nvim-lua/plenary.nvim' },
  },
  build = 'make tiktoken',

  config = function(_)
    require('copilot').setup {}
    require('CopilotChat').setup {
      debug = true,
      chat_autocomplete = true,
    }
  end,
}
