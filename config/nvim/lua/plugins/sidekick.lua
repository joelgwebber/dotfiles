return {
  'folke/sidekick.nvim',

  opts = {
    nes = {
      enabled = false, -- Disable Next Edit Suggestions entirely
    },
    cli = {
      mux = {
        backend = 'tmux',
        enabled = true,
      },
      -- Performance optimizations
      scrollback = 1000, -- Limit scrollback to prevent performance issues
      timeout = 30000, -- 30 second timeout for model loading

      -- Window management - make sidekick behave more like toggleterm
      win = {
        layout = "right", -- Keep default right side placement
        split = {
          width = 100,     -- Fixed width like your terminals
          height = 0,      -- Use default height
        },
        wo = {
          winfixwidth = true,  -- Prevent sidekick from being resized
          number = false,      -- No line numbers in sidekick
          relativenumber = false,
        },
      },

      tools = {
        claude = {
          cmd = { 'claude' },
          -- Cache model list to avoid repeated API calls
          cache = true,
        },
      },
    },
  },

  -- Simplified keybindings
  keys = {
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      mode = { "n", "v" },
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function()
        -- Use filter to only show installed tools for faster loading
        require("sidekick.cli").select({ filter = { installed = true } })
      end,
      desc = "Sidekick Select CLI",
    },
    {
      "<leader>as",
      function() require("sidekick.cli").send({ selection = true }) end,
      mode = { "v" },
      desc = "Sidekick Send Visual Selection",
    },
    {
      "<leader>ap",
      function() require("sidekick.cli").prompt() end,
      mode = { "n", "v" },
      desc = "Sidekick Select Prompt",
    },
    {
      "<c-.>",
      function() require("sidekick.cli").focus() end,
      mode = { "n", "x", "i", "t" },
      desc = "Sidekick Switch Focus",
    },
  },
}
