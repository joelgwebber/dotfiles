return {
  'CopilotC-Nvim/CopilotChat.nvim',
  branch = 'canary',
  dependencies = {
    { 'zbirenbaum/copilot.lua' },
    { 'nvim-lua/plenary.nvim' },
  },
  build = 'make tiktoken',

  config = function(_)
    require('CopilotChat.integrations.cmp').setup()
    require('CopilotChat').setup {
      debug = true,
    }
  end,
}
