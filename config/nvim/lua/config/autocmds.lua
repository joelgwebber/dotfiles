-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Force mini.files to use our color scheme's border highlights
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = function()
    -- Get colors from current scheme
    local float_bg = vim.api.nvim_get_hl(0, { name = 'NormalFloat' }).bg
    local border_fg = vim.api.nvim_get_hl(0, { name = 'FloatBorder' }).fg

    -- Apply to mini.files specific highlights (override the defaults)
    vim.api.nvim_set_hl(0, 'MiniFilesBorder', { fg = border_fg, bg = float_bg })
    vim.api.nvim_set_hl(0, 'MiniFilesNormal', { link = 'NormalFloat' })
    vim.api.nvim_set_hl(0, 'MiniFilesBorderModified', { fg = vim.api.nvim_get_hl(0, { name = 'DiagnosticWarn' }).fg, bg = float_bg })
  end,
  desc = 'Apply correct border colors to mini.files after colorscheme change',
})
