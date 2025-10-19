-- Autocompletion
return {
  'hrsh7th/nvim-cmp',
  event = 'InsertEnter',

  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-nvim-lsp-signature-help',
    'quangnguyen30192/cmp-nvim-tags',
  },

  config = function()
    local cmp = require 'cmp'
    cmp.setup {
      completion = { completeopt = 'menu,menuone,noinsert' },

      -- For an understanding of why these mappings were
      -- chosen, you will need to read `:help ins-completion`
      --
      -- No, but seriously. Please read `:help ins-completion`, it is really good!
      mapping = cmp.mapping.preset.insert {
        -- Select the [p]revious / [n]ext item
        ['<C-n>'] = cmp.mapping.select_next_item(),
        ['<C-p>'] = cmp.mapping.select_prev_item(),

        -- Accept ([y]es) the completion.
        --  This will auto-import if your LSP supports it.
        --  This will expand snippets if the LSP sent a snippet.
        ['<C-y>'] = cmp.mapping.confirm { select = true },

        -- Manually trigger a completion from nvim-cmp.
        --  Generally you don't need this, because nvim-cmp will display
        --  completions whenever it has completion options available.
        ['<C-Space>'] = cmp.mapping.complete {},
      },

      sources = {
        { name = 'nvim_lsp' },
        { name = 'path' },
        { name = 'tags' },
        { name = 'nvim_lsp_signature_help' },
      },
    }
  end,
}
