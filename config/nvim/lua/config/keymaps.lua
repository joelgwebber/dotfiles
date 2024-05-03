-- Change next/prev tab from H/L to other stuff.
vim.keymap.del("n", "H")
vim.keymap.del("n", "L")

-- Switch from neo-tree's slow "buffer explorer" to "Telescope buffers".
vim.keymap.del("n", "<Leader>be")
vim.keymap.set("n", "<Leader>be", "<Cmd>Telescope buffers<cr>")

-- vim.keymap.set({ "n", "t" }, "[b", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
-- vim.keymap.set({ "n", "t" }, "]b", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
-- vim.keymap.set({ "n", "t" }, "[B", "<cmd>BufferLineMovePrev<cr>", { desc = "Prev buffer" })
-- vim.keymap.set({ "n", "t" }, "]B", "<cmd>BufferLineMoveNext<cr>", { desc = "Next buffer" })
--
-- vim.keymap.set({ "n", "t" }, "<C-D-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
-- vim.keymap.set({ "n", "t" }, "<C-D-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
-- vim.keymap.set({ "n", "t" }, "<C-D-S-h>", "<cmd>BufferLineMovePrev<cr>", { desc = "Prev buffer" })
-- vim.keymap.set({ "n", "t" }, "<C-D-S-l>", "<cmd>BufferLineMoveNext<cr>", { desc = "Next buffer" })

-- Neotree reveal current file.
vim.keymap.set({ "n" }, "<C-n>", "<cmd>Neotree filesystem reveal<cr>", { desc = "Reveal file" })

-- Add basic shortcuts for yarepl.
vim.keymap.set("n", "<Leader>rr", "<cmd>REPLStart<cr>")
vim.keymap.set("n", "<Leader>rr", "<cmd>REPLStart<cr>")
vim.keymap.set("n", "<Leader>rf", "<cmd>REPLFocus<cr>")
vim.keymap.set("n", "<Leader>rs", "<cmd>REPLSendOperator<cr>")
vim.keymap.set("v", "<Leader>r", "<cmd>REPLSendVisual<cr>")
vim.keymap.set("n", "<Leader>rl", "<cmd>REPLSendLine<cr>")

-- I hate the regular join behavior. This skips the extra space.
vim.keymap.set("n", "J", "<cmd>join!<cr>")

-- Flyboy LLM keys.
vim.keymap.set("n", "<Leader>a<cr>", "<cmd>FlyboySendMessage<cr>")
vim.keymap.set("n", "<Leader>aa", "<cmd>FlyboyOpen<cr>")
vim.keymap.set("v", "<Leader>a", "<cmd>FlyboyOpen visual<cr>")

-- Clear scrollback hack for the terminal.
vim.keymap.set("t", "<C-S-l>", "<cmd>lua ClearScrollback()<cr><C-l>")

function ClearScrollback()
  local sb = vim.bo.scrollback
  vim.bo.scrollback = 1
  vim.bo.scrollback = sb
end
