return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',

  config = function()
    require('copilot').setup {
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = false, -- Disable default accept to create our own
          accept_word = false,
          accept_line = false,
          next = '<C-=>', -- Ctrl+= for next suggestion
          prev = '<C-->', -- Ctrl+- for previous suggestion
          dismiss = '<C-]>',
        },
      },

      panel = {
        enabled = true,
        auto_refresh = false,
        keymap = {
          jump_prev = '[[',
          jump_next = ']]',
          accept = '<CR>',
          refresh = 'gr',
          open = '<M-CR>',
        },
        layout = {
          position = 'bottom', -- | top | left | right | horizontal | vertical
          ratio = 0.4,
        },
      },

      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },

      copilot_node_command = '/opt/homebrew/bin/node', -- Node.js version must be > 18.x
      server_opts_overrides = {},
    }
  end,
}
