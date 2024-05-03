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

require("neo-tree").setup({
  -- Fix annoying split when opening a file while a terminal is open.
  open_files_do_not_replace_types = {},

  -- Turn on file following.
  -- TODO: This doesn't actually seem to work?
  default_component_configs = {
    buffers = {
      follow_current_file = {
        enable = true,
        leave_dirs_open = false,
      },
    },
    filesystem = {
      follow_current_file = {
        enable = true,
        leave_dirs_open = false,
      },
    },
  },
})

require("telescope").setup({
  pickers = {
    buffers = {
      show_all_buffers = true,
      sort_mru = true,
      mappings = {
        n = {
          ["d"] = "delete_buffer",
        },
      },
    },
  },
})

-- Load mini.bufremove to avoid weird window behaviors when closing buffers.
local bufremove = require("mini.bufremove")
bufremove.setup({})
vim.api.nvim_create_user_command("Q", function()
  bufremove.delete()
end, {})

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
