return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require('toggleterm').setup {
      size = function(term)
        if term.direction == 'horizontal' then
          return 25  -- Fixed 25 rows for horizontal terminals
        elseif term.direction == 'vertical' then
          return 100 -- Fixed 100 columns for vertical terminals
        end
      end,
      open_mapping = false, -- We'll handle this manually
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = false, -- We'll handle keymaps manually
      terminal_mappings = false,
      persist_size = true,
      persist_mode = true,
      direction = 'vertical', -- Default direction
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,

      -- Floating terminal configuration
      float_opts = {
        border = 'curved',
        winblend = 0,
        highlights = {
          border = 'Normal',
          background = 'Normal',
        },
        width = function()
          return math.floor(vim.o.columns * 0.8)
        end,
        height = function()
          return math.floor(vim.o.lines * 0.8)
        end,
      },
    }
  end,

  keys = {
    -- Quick access to main terminal (terminal 1, vertical)
    { '<C-,>', '<cmd>1ToggleTerm direction=vertical<cr>', desc = 'Toggle main terminal', mode = { 'n', 'i', 't' } },

    -- Terminal 1 (primary) - different directions
    { '<leader>tv', '<cmd>1ToggleTerm direction=vertical<cr>', desc = '[t]erminal 1 [v]ertical' },
    { '<leader>th', '<cmd>1ToggleTerm direction=horizontal<cr>', desc = '[t]erminal 1 [h]orizontal' },
    { '<leader>tf', '<cmd>1ToggleTerm direction=float<cr>', desc = '[t]erminal 1 [f]loat' },

    -- Terminal 2 (secondary)
    { '<leader>t2v', '<cmd>2ToggleTerm direction=vertical<cr>', desc = '[t]erminal [2] [v]ertical' },
    { '<leader>t2h', '<cmd>2ToggleTerm direction=horizontal<cr>', desc = '[t]erminal [2] [h]orizontal' },
    { '<leader>t2f', '<cmd>2ToggleTerm direction=float<cr>', desc = '[t]erminal [2] [f]loat' },

    -- Terminal 3 (tertiary)
    { '<leader>t3v', '<cmd>3ToggleTerm direction=vertical<cr>', desc = '[t]erminal [3] [v]ertical' },
    { '<leader>t3h', '<cmd>3ToggleTerm direction=horizontal<cr>', desc = '[t]erminal [3] [h]orizontal' },
    { '<leader>t3f', '<cmd>3ToggleTerm direction=float<cr>', desc = '[t]erminal [3] [f]loat' },

    -- Terminal utilities
    { '<leader>ts', '<cmd>TermSelect<cr>', desc = '[t]erminal [s]elect' },
  },
}
