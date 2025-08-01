-- Code formatting
return {
  'stevearc/conform.nvim',
  lazy = false,

  opts = {
    notify_on_error = false,

    format_on_save = function(bufnr)
      -- Disable "format_on_save lsp_fallback" for languages that don't
      -- have a well standardized coding style. You can add additional
      -- languages here or re-enable it for the disabled ones.
      local disable_filetypes = { c = true, cpp = true }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,

    formatters_by_ft = {
      lua = { 'stylua' },
      python = { 'isort', 'black' },
      go = { 'gofmt' },
      css = { 'prettier' },
      scss = { 'prettier' },
      json = { 'jq' },
      html = { 'djlint' },
      javascript = { 'prettier' },
      javascriptreact = { 'prettier' },
      typescript = { 'prettier' },
      typescriptreact = { 'prettier' },

      -- This formatter's way too strongly opinionated to be broadly useful.
      -- markdown = { 'mdformat' },
    },
  },
}
