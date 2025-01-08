return {
  'GeorgesAlkhouri/nvim-aider',
  cmd = {
    'AiderTerminalToggle',
  },
  keys = {
    { '<leader>a/', '<cmd>AiderTerminalToggle<cr>', desc = 'Open Aider' },
    { '<leader>as', '<cmd>AiderTerminalSend<cr>', desc = 'Send to Aider', mode = { 'n', 'v' } },
    { '<leader>ac', '<cmd>AiderQuickSendCommand<cr>', desc = 'Send Command To Aider' },
    { '<leader>ab', '<cmd>AiderQuickSendBuffer<cr>', desc = 'Send Buffer To Aider' },
    { '<leader>a+', '<cmd>AiderQuickAddFile<cr>', desc = 'Add File to Aider' },
    { '<leader>a-', '<cmd>AiderQuickDropFile<cr>', desc = 'Drop File from Aider' },
  },
  dependencies = {
    'folke/snacks.nvim',
    'nvim-telescope/telescope.nvim',
    'catppuccin/nvim',
  },
  config = function()
    require('nvim_aider').setup {
      -- Command line arguments passed to aider
      args = {
        '--no-auto-commits',
        '--dark-mode',
        '--pretty',
        '--vim',
        '--stream',
        '--map-refresh',
        'files',
      },
      win = {
        style = 'nvim_aider',
        position = 'bottom',
      },
    }
  end,
}
