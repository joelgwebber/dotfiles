local M = {}

M.defaults = {
  update_interval = 2000,
  window = {
    width = 70,
    height = 15,
    border = 'rounded',
  },
  artwork = {
    enabled = false,  -- Disabled by default - experimental feature
    max_width = 300,
    max_height = 300,
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.defaults, opts or {})
end

return M
