local M = {}

M.defaults = {
  update_interval = 2000,
  window = {
    width = 70,
  },
  artwork = {
    enabled = true,  -- Enabled with docked window (more stable than floating)
    max_width = 300,
    max_height = 300,
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
