-- Change next/prev tab from H/L to [Shift-]Tab
vim.keymap.del("n", "H")
vim.keymap.del("n", "L")
vim.keymap.set({ "n", "t" }, "<C-D-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
vim.keymap.set({ "n", "t" }, "<C-D-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
vim.keymap.set({ "n", "t" }, "<C-D-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev buffer" })
vim.keymap.set({ "n", "t" }, "<C-D-S-l>", "<cmd>BufferLineMoveNext<cr>", { desc = "Next buffer" })
vim.keymap.set({ "n", "t" }, "<C-D-S-h>", "<cmd>BufferLineMovePrev<cr>", { desc = "Prev buffer" })

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
