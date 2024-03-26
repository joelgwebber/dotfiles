return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff_lsp = { mason = false },
        pyright = { mason = false },
      },
    },
  },
}
