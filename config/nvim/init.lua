require("config.lazy")

require("lspconfig").pyright.setup({})
require("lspconfig").gopls.setup({})
require("lspconfig").tsserver.setup({})
require("telescope").load_extension("workspaces")
require("telescope").load_extension("REPLShow")
require("workspaces").setup({
  extensions = {
    workspaces = {
      keep_insert = true,
    },
  },
})

-- Fix annoying split when opening a file while a terminal is open.
require("neo-tree").setup({
  open_files_do_not_replace_types = {},
})

require("tokyonight").setup({
  style = "storm",
  terminal_colors = true,
  styles = {
    comments = { italic = true },
  },
  on_colors = function(colors) end,
  on_highlights = function(highlights, colors) end,
})

vim.cmd([[hi WinSeparator guifg=#3e68d7 guibg=#222436]])
vim.cmd([[source ~/.vimrc]])

-- vim.opt.runtimepath:prepend("~/src/nvcalc.nvim")
-- require("nvcalc").nvcalc()
