# apple-music.nvim

A performant, feature-rich Apple Music controller for Neovim with album artwork support.

## Features

- **Floating UI** with comprehensive track information
- **Album artwork** display (Kitty terminal protocol) - EXPERIMENTAL
- **Extended metadata**:
  - Genre, Year, Composer
  - Track/Disc numbers
  - Play count, Bit rate
  - Favorited/Disliked status (❤/💔)
  - Album artist (when different from track artist)
- **Real-time updates** with async I/O (non-blocking)
- **Playback controls** (play/pause, next/previous, shuffle)
- **Volume control** with visual indicator
- **Clean, minimal interface**

## Requirements

- Neovim 0.8+
- macOS
- Apple Music
- **Kitty terminal** (for album artwork - optional)

## Performance

This plugin uses:
- **Batched AppleScript execution** - One script call instead of 7+ per refresh
- **Async I/O** via `vim.system()` - Never blocks the editor
- **Smart caching** - Reduces redundant queries

## Installation

### With lazy.nvim (local development)

```lua
{
  dir = vim.fn.expand('~/dotfiles/plugins/apple-music.nvim'),
  name = 'apple-music.nvim',
  dependencies = {
    '3rd/image.nvim',  -- For album artwork (Kitty terminal only)
  },
  config = function()
    require('apple-music').setup({
      update_interval = 2000,  -- UI refresh rate in ms
      window = {
        width = 70,
        height = 15,
        border = 'rounded',  -- 'single', 'double', 'rounded', 'solid', 'shadow'
      },
      artwork = {
        enabled = true,
        max_width = 300,
        max_height = 300,
      },
    })
  end,
  keys = {
    { '<leader>mu', function() require('apple-music').toggle_ui() end, desc = 'Toggle [u]i' },
    { '<leader>mp', function() require('apple-music').play_pause() end, desc = 'Toggle [p]lay/pause' },
    { '<leader>mn', function() require('apple-music').next_track() end, desc = '[n]ext track' },
    { '<leader>mN', function() require('apple-music').previous_track() end, desc = 'Previous track' },
    { '<leader>ms', function() require('apple-music').toggle_shuffle() end, desc = 'Toggle [s]huffle' },
    { '<leader>m=', function() require('apple-music').increase_volume() end, desc = 'Volume up' },
    { '<leader>m-', function() require('apple-music').decrease_volume() end, desc = 'Volume down' },
  },
}
```

## Usage

### Global Keybindings

- `<leader>mu` - Toggle UI
- `<leader>mp` - Play/pause
- `<leader>mn` - Next track
- `<leader>mN` - Previous track
- `<leader>ms` - Toggle shuffle
- `<leader>m=` - Volume up
- `<leader>m-` - Volume down

### UI Keybindings (when window is open)

- `q` / `<Esc>` - Close UI
- `p` - Play/pause
- `n` - Next track
- `N` - Previous track
- `=` - Volume up
- `-` - Volume down
- `s` - Toggle shuffle

## Configuration

```lua
require('apple-music').setup({
  -- UI refresh interval in milliseconds
  update_interval = 2000,

  -- Window configuration
  window = {
    width = 70,
    height = 15,
    border = 'rounded',  -- 'single', 'double', 'rounded', 'solid', 'shadow'
  },

  -- Album artwork (requires Kitty terminal)
  artwork = {
    enabled = true,
    max_width = 300,
    max_height = 300,
  },
})
```

## Architecture

```
lua/apple-music/
├── init.lua      # Public API
├── config.lua    # Configuration management
├── player.lua    # AppleScript interface (async)
├── ui.lua        # Floating window UI
└── artwork.lua   # Album artwork display (image.nvim)
```

## Metadata Available

The plugin fetches all available track metadata from Apple Music:

- Basic: name, artist, album, duration, position
- Extended: genre, year, rating, composer, album_artist
- Stats: track/disc numbers, play count, bit rate
- Status: favorited, disliked, player state
- Artwork: album art (if available)

## Troubleshooting

### Album artwork (EXPERIMENTAL)

**Note**: Artwork support is experimental and disabled by default due to issues with image.nvim and floating windows.

**Known issues**:
- Images may persist as "ghosts" when closing the UI
- Window may jump/flicker when loading artwork
- Images may not render in the correct position

**To enable (at your own risk)**:
```lua
artwork = { enabled = true }
```

**Requirements**:
1. Verify you're using **Kitty terminal**: `echo $TERM` should show `xterm-kitty`
2. Check if image.nvim is installed: `:lua print(require('image'))`

**If you experience issues**, disable it: `artwork = { enabled = false }`

### UI not updating

1. Check Apple Music is running
2. Try manually refreshing: close and reopen the UI
3. Increase `update_interval` if experiencing performance issues

## Development

This is a local plugin under active development.

### Reload Changes

1. Edit files in `plugins/apple-music.nvim/lua/apple-music/`
2. Reload: `:Lazy reload apple-music.nvim`
3. Reopen UI: `<leader>mu`

### Testing

Test individual components:

```lua
-- Test player state
:lua vim.print(require('apple-music.player').get_state_async(vim.print))

-- Test artwork extraction
:lua require('apple-music.player').get_artwork_async(vim.print)
```

## License

MIT
