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

-- vim.opt.runtimepath:prepend("~/src/nvcalc.nvim")
-- require("nvcalc").nvcalc()

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

-- OSC52 stuff for ssh.
local function copy(lines, _)
  require("osc52").copy(table.concat(lines, "\n"))
end

local function paste()
  return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
end

vim.g.clipboard = {
  name = "osc52",
  copy = { ["+"] = copy, ["*"] = copy },
  paste = { ["+"] = paste, ["*"] = paste },
}

-- Now the '+' register will copy to system clipboard using OSC52
-- vim.keymap.set("n", "<leader>C", '"+y')
-- vim.keymap.set("n", "<leader>CC", '"+yy')
