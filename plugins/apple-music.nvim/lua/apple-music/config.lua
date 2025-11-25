local M = {}

M.defaults = {
	update_interval = 2000,
	window = {
		width = 56,  -- Increased to accommodate queue artwork (4x2) + text
	},
	artwork = {
		enabled = true, -- Enabled with docked window (more stable than floating)
		max_width_chars = 40, -- Maximum width in character cells
		max_height_chars = 20, -- Maximum height in character cells (half of width for square aspect ratio)
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
