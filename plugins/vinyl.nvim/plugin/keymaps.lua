-- Default keymaps for vinyl.nvim
-- Users can disable these by setting vim.g.vinyl_no_default_keymaps = true

if vim.g.vinyl_no_default_keymaps then
	return
end

local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { silent = true, desc = desc })
end

-- Main keymaps with <leader>m prefix
map("n", "<leader>m<Space>", ":Vinyl play<CR>", "Music: Play/pause")
map("n", "<leader>mm", ":Vinyl toggle<CR>", "Music: Toggle UI")
map("n", "<leader>mn", ":Vinyl next<CR>", "Music: Next track")
map("n", "<leader>mN", ":Vinyl prev<CR>", "Music: Previous track")
map("n", "<leader>ms", ":Vinyl shuffle<CR>", "Music: Toggle shuffle")

-- Library browsing
map("n", "<leader>mp", ":Vinyl playlists<CR>", "Music: Browse playlists")
map("n", "<leader>ma", ":Vinyl albums<CR>", "Music: Browse albums")
map("n", "<leader>mt", ":Vinyl tracks<CR>", "Music: Browse tracks")
map("n", "<leader>mr", ":Vinyl artists<CR>", "Music: Browse artists")

-- Backend management
map("n", "<leader>mb", ":Vinyl backend<CR>", "Music: Show current backend")
