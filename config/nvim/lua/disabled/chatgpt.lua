return {
  "jackMort/ChatGPT.nvim",
  event = "VeryLazy",
  config = function()
    require("chatgpt").setup({
      -- gpt-4-turbo-preview
      openai_params = {
        model = "gpt-4-turbo-preview",
      },
      openai_edit_params = {
        model = "gpt-4-turbo-preview",
      },
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "nvim-lua/plenary.nvim",
    "folke/trouble.nvim",
    "nvim-telescope/telescope.nvim",
  },
}
