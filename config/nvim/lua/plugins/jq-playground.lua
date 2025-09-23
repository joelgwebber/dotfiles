return {
  'yochem/jq-playground.nvim',
  dependencies = {
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '<leader>jq', '<cmd>JqPlayground<cr>', desc = 'Open JQ Playground' },
    { '<leader>fq', function()
        -- Temporarily set cmd to fq and open playground
        local config = require("jq-playground.config")
        local original_cmd = vim.deepcopy(config.config.cmd)
        config.config.cmd = { "fq" }
        vim.cmd("JqPlayground")
        -- Restore original cmd after a short delay
        vim.defer_fn(function()
          config.config.cmd = original_cmd
        end, 100)
      end, desc = 'Open FQ Playground'
    },
  },
  opts = {
    cmd = { "jq" },  -- Default to jq, can be overridden to { "fq" }
    query = '.',
    disable_default_keymap = false,
    output_window = {
      split_direction = "right",
      width = nil,
      height = nil,
      scratch = true,
      filetype = "json",
      name = "jq output",
    },
    query_window = {
      split_direction = "below",
      width = nil,
      height = 0.3,
      scratch = false,
      filetype = "jq",
      name = "query editor",
    },
    keymaps = {
      close = { 'q', '<Esc>' },
      run = '<Enter>',
    },
  },
  cmd = { 'JqPlayground', 'FqPlayground' },
  config = function(_, opts)
    require("jq-playground").setup(opts)

    -- Create a custom command for FQ playground
    vim.api.nvim_create_user_command("FqPlayground", function(params)
      local config = require("jq-playground.config")
      local original_cmd = vim.deepcopy(config.config.cmd)
      config.config.cmd = { "fq" }
      require("jq-playground.playground").init_playground(params.fargs[1])
      -- Restore original cmd after playground is initialized
      vim.defer_fn(function()
        config.config.cmd = original_cmd
      end, 100)
    end, {
      desc = "Start fq query editor and live preview",
      nargs = "?",
      complete = "file",
    })
  end,
}