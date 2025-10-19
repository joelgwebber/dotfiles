return {
  'folke/sidekick.nvim',

  opts = {
    cli = {
      mux = {
        backend = 'tmux',
        enabled = true,
      },
      tools = {
        claude = {
          cmd = { 'claude' },
        },
        ['claude-resume'] = {
          cmd = { 'claude', '--resume' },
        },
      },
    },
  },

  -- stylua: ignore
  keys = {
    -- {
    --   "<tab>",
    --   function() require("sidekick").nes_jump_or_apply() end,
    --   mode = { "i", "n" },
    --   expr = true,
    --   desc = "Goto/Apply Next Edit Suggestion",
    -- },
    {
      "<leader>aa",
      function() require("sidekick.cli").toggle() end,
      mode = { "n", "v" },
      desc = "Sidekick Toggle CLI",
    },
    {
      "<leader>as",
      function() require("sidekick.cli").select() end,
      -- Or to select only installed tools:
      -- require("sidekick.cli").select({ filter = { installed = true } })
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
    {
      "<leader>ac",
      function() require("sidekick.cli").toggle({ name = "claude", focus = true }) end,
      desc = "Sidekick Claude Toggle",
      mode = { "n", "v" },
    },
    {
      "<leader>ar",
      function() require("sidekick.cli").toggle({ name = "claude-resume", focus = true }) end,
      desc = "Sidekick Claude Resume",
      mode = { "n", "v" },
    },
    -- {
    --   "<leader>an",
    --   function() require("sidekick.nes").update() end,
    --   desc = "Manually trigger NES suggestions",
    --   mode = { "n", "v" },
    -- },
    -- {
    --   "<C-a>",
    --   function() require("sidekick.nes").update() end,
    --   desc = "Manually trigger NES suggestions (insert mode)",
    --   mode = { "i" },
    -- },
  },
}
