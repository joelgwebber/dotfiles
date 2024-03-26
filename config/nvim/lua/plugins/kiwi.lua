return {
  "serenevoid/kiwi.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    {
      name = "work",
      path = "/Users/joel/Drive/kiwi",
    },
    {
      name = "personal",
      path = "/Users/joel/FullStory/My Drive/kiwi_personal",
    },
  },
  keys = {
    { "<leader>ww", ':lua require("kiwi").open_wiki_index("work")<cr>', desc = "Open Wiki index" },
    { "<leader>wp", ':lua require("kiwi").open_wiki_index("personal")<cr>', desc = "Open index of personal wiki" },
    { "T", ':lua require("kiwi").todo.toggle()<cr>', desc = "Toggle Markdown Task" },
  },
  lazy = true,
}
