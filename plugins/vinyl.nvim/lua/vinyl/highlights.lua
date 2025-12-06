-- Highlight group management for Apple Music UI
local M = {}

-- Default highlight group mappings
-- These link to standard Neovim highlight groups for colorscheme compatibility
M.default_links = {
  -- Main track info
  AppleMusicTitle = 'Title',           -- Track name (bold, prominent)
  AppleMusicArtist = 'Directory',      -- Artist name (secondary focus)
  AppleMusicAlbum = 'Comment',         -- Album name (tertiary)

  -- Progress and time
  AppleMusicProgress = 'String',       -- Filled portion of progress bar
  AppleMusicProgressEmpty = 'Comment', -- Empty portion of progress bar
  AppleMusicTime = 'Number',           -- Time display (3:24 / 4:30)

  -- Metadata
  AppleMusicLabel = 'Comment',         -- Metadata labels (Genre:, Year:, etc.)
  AppleMusicValue = 'Normal',          -- Metadata values
  AppleMusicMetaSpecial = 'Special',   -- Special metadata (bit rate, play count)

  -- Status indicators
  AppleMusicShuffle = 'Function',      -- Shuffle indicator
  AppleMusicFavorite = 'String',       -- ❤ Favorited (typically red/pink)
  AppleMusicDislike = 'WarningMsg',    -- 💔 Disliked (typically warning color)

  -- Volume
  AppleMusicVolume = 'Number',         -- Volume percentage
  AppleMusicVolumeIcon = 'Special',    -- Volume icon

  -- Queue items
  AppleMusicQueueTrack = 'Normal',     -- Queue track name
  AppleMusicQueueArtist = 'Comment',   -- Queue artist name (dimmed)
  AppleMusicQueueHeader = 'Title',     -- "Up Next" header

  -- Special elements
  AppleMusicBorder = 'FloatBorder',    -- Window border
  AppleMusicNormal = 'Normal',         -- Normal text / background
}

-- Setup highlight groups
function M.setup()
  -- Set all highlight groups with default = true
  -- This allows users to override in their colorscheme or config
  for group, link in pairs(M.default_links) do
    vim.api.nvim_set_hl(0, group, {
      link = link,
      default = true,
    })
  end
end

-- Helper to get a highlight group name for use in UI rendering
function M.get(name)
  return 'AppleMusic' .. name
end

return M
