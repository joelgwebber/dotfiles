return {
  "gsuuon/model.nvim",

  cmd = { "M", "Model", "Mchat" },
  init = function()
    vim.filetype.add({
      extension = {
        mchat = "mchat",
      },
    })
  end,

  ft = "mchat",

  keys = {
    { "<C-m>d", ":Mdelete<cr>", mode = "n" },
    { "<C-m>s", ":Mselect<cr>", mode = "n" },
    { "<C-m><space>", ":Mchat<cr>", mode = "n" },
  },

  config = function()
    local openai = require("model.providers.openai")
    openai.initialize({
      model = "gpt-4",
    })
    require("model").setup({
      -- default_prompt = {
      --   provider = openai,
      --   options = {
      --     model = "gpt-4-turbo-preview",
      --   },
      -- },
      prompts = {
        ["openai"] = {
          provider = openai,
          options = {
            model = "gpt-4",
          },
          builder = function(input)
            return {
              model = "gpt-4",
              temperature = 0.3,
              max_tokens = 400,
              messages = {
                {
                  role = "system",
                  content = "You are helpful assistant.",
                },
                { role = "user", content = input },
              },
            }
          end,
        },
      },
      -- chats = {
      --   testes = {
      --     provider = openai,
      --     create = function(input, ctx) end,
      --     run = function(messages, config) end,
      --     options = {
      --       model = "gpt-4-turbo-preview",
      --     },
      --   },
      -- },
    })
  end,
}

-- require("model").setup({
--   chats = {
--     gpt4 = {
--       provider = openai,
--       options = {
--         model = "gpt-4-turbo-preview",
--       },
--     },
--   },
-- })

-- require('model.providers.llamacpp').setup({
--   binary = '~/path/to/server/binary',
--   models = '~/path/to/models/directory'
-- })
