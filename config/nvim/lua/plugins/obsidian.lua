-- Obsidian vault navigation and editing
return {
  'epwalsh/obsidian.nvim',
  event = 'VimEnter',

  version = '*', -- recommended, use latest release instead of latest commit
  lazy = true,
  ft = 'markdown',

  dependencies = {
    'nvim-lua/plenary.nvim',
  },

  opts = {
    workspaces = {
      {
        name = 'personal',
        path = '~/vaults/personal',
      },
      {
        name = 'work',
        path = '~/FullStory/My Drive/work',
      },
    },

    ui = {
      checkboxes = {
        -- TODO: Look into the 'patched font' for checkboxes mentioned in the docs.
        [' '] = { char = '☐', hl_group = 'ObsidianTodo' },
        ['x'] = { char = '✔', hl_group = 'ObsidianDone' },
      },
    },

    note_id_func = function(title)
      if title ~= nil then
        -- If title is given, transform it into valid file name.
        return title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      end

      -- Otherwise, just use a random 4 characters.
      title = ''
      for _ = 1, 4 do
        title = title .. string.char(math.random(65, 90))
      end
      return title
    end,
  },

  config = function(_, opts)
    require('obsidian').setup(opts)
  end,
}
