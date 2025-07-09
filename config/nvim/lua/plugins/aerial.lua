return {
  'stevearc/aerial.nvim',
  opts = {},
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-tree/nvim-web-devicons',
  },

  config = function()
    require('aerial').setup {
      backends = { 'treesitter', 'lsp' },
      layout = {
        default_direction = 'prefer_right',
        -- placement = 'edge',

        -- These control the width of the aerial window.
        -- They can be integers or a float between 0 and 1 (e.g. 0.4 for 40%)
        -- min_width and max_width can be a list of mixed types.
        -- max_width = {40, 0.2} means "the lesser of 40 columns or 20% of total"
        max_width = { 60, 0.2 },
        width = nil,
        min_width = 20,
      },

      show_guides = true,
      show_guide_lines = true,
      show_guide_tree = true,
      show_guide_text = true,
    }
  end,
}
