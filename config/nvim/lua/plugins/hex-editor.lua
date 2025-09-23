return {
  {
    'RaafatTurki/hex.nvim',
    config = function()
      require('hex').setup()

      -- Auto commands for binary files
      vim.api.nvim_create_autocmd({ "BufReadPre" }, {
        pattern = { "*.bin", "*.exe", "*.dat", "*.o", "*.so", "*.dylib" },
        callback = function()
          vim.cmd("let &bin=1")
        end
      })

      vim.api.nvim_create_autocmd({ "BufReadPost" }, {
        pattern = { "*.bin", "*.exe", "*.dat", "*.o", "*.so", "*.dylib" },
        callback = function()
          vim.cmd([[
            if &bin
              %!xxd
              set ft=xxd
            endif
          ]])
        end
      })

      vim.api.nvim_create_autocmd({ "BufWritePre" }, {
        pattern = { "*.bin", "*.exe", "*.dat", "*.o", "*.so", "*.dylib" },
        callback = function()
          vim.cmd([[
            if &bin
              %!xxd -r
            endif
          ]])
        end
      })

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        pattern = { "*.bin", "*.exe", "*.dat", "*.o", "*.so", "*.dylib" },
        callback = function()
          vim.cmd([[
            if &bin
              %!xxd
              set nomod
            endif
          ]])
        end
      })
    end,
    cmd = { 'HexDump', 'HexAssemble', 'HexToggle' },
    keys = {
      { '<leader>hx', '<cmd>HexToggle<cr>', desc = 'Toggle hex view' },
    }
  }
}