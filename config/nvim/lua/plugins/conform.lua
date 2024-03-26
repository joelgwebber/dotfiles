return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = { "isort", "black" },
      javascript = { { "prettierd", "prettier" } },
    },
    formatters = {
      isort = { args = { "--profile", "black" } },
      black = { prepend_args = { "--fast", "--line-length", "140" } },
    },
  },
}
