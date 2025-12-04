# apple-music.nvim

A performant, feature-rich Apple Music controller for Neovim with album artwork support.

## Features

- **Docked UI** with comprehensive track information
- **Album artwork** display (direct Kitty graphics protocol implementation)
- **Library browsing** with Telescope/fzf-lua integration:
  - Browse and play tracks
  - Browse and play albums
  - Browse and play by artist
  - Browse and play playlists
- **Extended metadata**:
  - Genre, Year, Composer
  - Track/Disc numbers
  - Play count, Bit rate
  - Favorited/Disliked status (❤/💔)
  - Album artist (when different from track artist)
- **Real-time updates** with async I/O (non-blocking)
- **Playback controls** (play/pause, next/previous, shuffle)
- **Precise seeking** (±5s, ±30s with h/l/H/L)
- **Volume control** with visual indicator
- **Instant UI feedback** - optimistic updates for all actions
- **Clean, minimal docked interface**

## Requirements

- Neovim 0.8+
- macOS
- Apple Music
- **Kitty terminal** (for album artwork - optional)

## Performance

This plugin uses:
- **Batched AppleScript execution** - One script call instead of 7+ per refresh
- **Async I/O** via `vim.system()` - Never blocks the editor
- **Optimistic UI updates** - Instant visual feedback for all actions
- **Smart caching** - Reduces redundant queries on resize/volume
- **Direct Kitty protocol** - Efficient image repositioning without re-transmission

## Installation

### With lazy.nvim (local development)

```lua
{
  dir = vim.fn.expand('~/dotfiles/plugins/apple-music.nvim'),
  name = 'apple-music.nvim',
  -- No dependencies - direct Kitty graphics protocol implementation
  config = function()
    require('apple-music').setup({
      update_interval = 2000,  -- UI refresh rate in ms
      window = {
        width = 48,  -- Docked window width
      },
      artwork = {
        enabled = true,
        max_width_chars = 40,  -- Maximum width in character cells
        max_height_chars = 20, -- Maximum height in character cells
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
    -- Library browsing
    { '<leader>mt', function() require('apple-music').browse_tracks() end, desc = 'Browse [t]racks' },
    { '<leader>ma', function() require('apple-music').browse_albums() end, desc = 'Browse [a]lbums' },
    { '<leader>mA', function() require('apple-music').browse_artists() end, desc = 'Browse [A]rtists' },
    { '<leader>ml', function() require('apple-music').browse_playlists() end, desc = 'Browse p[l]aylists' },
  },
}
```

## Usage

### Global Keybindings

**Playback controls:**
- `<leader>mu` - Toggle UI
- `<leader>mp` - Play/pause
- `<leader>mn` - Next track
- `<leader>mN` - Previous track
- `<leader>ms` - Toggle shuffle
- `<leader>m=` - Volume up
- `<leader>m-` - Volume down

**Library browsing:**
- `<leader>mt` - Browse tracks
- `<leader>ma` - Browse albums
- `<leader>mA` - Browse artists
- `<leader>ml` - Browse playlists

### UI Keybindings (when window is open)

- `q` / `<Esc>` - Close UI
- `p` - Play/pause
- `n` - Next track
- `N` - Previous track
- `h` / `l` - Seek backward/forward 5 seconds
- `H` / `L` - Seek backward/forward 30 seconds
- `=` - Volume up
- `-` - Volume down
- `s` - Toggle shuffle

### Library Browsing

The plugin provides fuzzy-searchable browsers for your entire Apple Music library. The plugin automatically detects and uses:
1. **Telescope** (if available) - full-featured fuzzy finder
2. **fzf-lua** (if available) - fast alternative
3. **vim.ui.select** - built-in fallback

**Browse tracks** (`<leader>mt`):
- Displays all tracks in your library with artist and album info
- Fuzzy search by track name, artist, or album
- Press Enter to play selected track

**Browse albums** (`<leader>ma`):
- Shows all unique albums in your library
- Fuzzy search by album name or artist
- Press Enter to play the album (starts from first track)

**Browse artists** (`<leader>mA`):
- Lists all artists in your library
- Fuzzy search by artist name
- Press Enter to play tracks by that artist

**Browse playlists** (`<leader>ml`):
- Shows all your user playlists
- Fuzzy search by playlist name
- Press Enter to play the playlist

## Configuration

```lua
require('apple-music').setup({
  -- UI refresh interval in milliseconds
  update_interval = 2000,

  -- Window configuration
  window = {
    width = 56,  -- Docked window width in columns
  },

  -- Album artwork (requires Kitty terminal)
  artwork = {
    enabled = true,
    max_width_chars = 40,  -- Maximum width in character cells
    max_height_chars = 20, -- Maximum height in character cells (2:1 ratio for square pixels)
  },
})
```

### Theming

The plugin uses standard Neovim highlight groups by default, so it automatically works with any colorscheme. You can customize the colors by overriding the highlight groups in your config:

```lua
-- Customize highlights (set these AFTER your colorscheme)
vim.api.nvim_set_hl(0, 'AppleMusicTitle', { fg = '#ff79c6', bold = true })      -- Track name
vim.api.nvim_set_hl(0, 'AppleMusicArtist', { fg = '#8be9fd' })                  -- Artist name
vim.api.nvim_set_hl(0, 'AppleMusicAlbum', { fg = '#6272a4', italic = true })    -- Album name
vim.api.nvim_set_hl(0, 'AppleMusicTime', { fg = '#f1fa8c' })                    -- Time display
vim.api.nvim_set_hl(0, 'AppleMusicVolume', { fg = '#50fa7b' })                  -- Volume display
vim.api.nvim_set_hl(0, 'AppleMusicQueueTrack', { fg = '#f8f8f2' })              -- Queue track names
vim.api.nvim_set_hl(0, 'AppleMusicQueueArtist', { fg = '#6272a4' })             -- Queue artists (dimmed)
vim.api.nvim_set_hl(0, 'AppleMusicShuffle', { fg = '#bd93f9' })                 -- Shuffle indicator
```

#### Available Highlight Groups

| Group | Default Link | Description |
|-------|--------------|-------------|
| `AppleMusicTitle` | `Title` | Track name (bold, prominent) |
| `AppleMusicArtist` | `Directory` | Artist name (secondary focus) |
| `AppleMusicAlbum` | `Comment` | Album name (tertiary) |
| `AppleMusicProgress` | `String` | Filled portion of progress bar |
| `AppleMusicProgressEmpty` | `Comment` | Empty portion of progress bar |
| `AppleMusicTime` | `Number` | Time display (3:24 / 4:30) |
| `AppleMusicLabel` | `Comment` | Metadata labels (Genre:, Year:) |
| `AppleMusicValue` | `Normal` | Metadata values |
| `AppleMusicMetaSpecial` | `Special` | Special metadata (bit rate, play count) |
| `AppleMusicShuffle` | `Function` | Shuffle indicator |
| `AppleMusicFavorite` | `String` | ❤ Favorited status |
| `AppleMusicDislike` | `WarningMsg` | 💔 Disliked status |
| `AppleMusicVolume` | `Number` | Volume percentage |
| `AppleMusicVolumeIcon` | `Special` | Volume icon |
| `AppleMusicQueueTrack` | `Normal` | Queue track name |
| `AppleMusicQueueArtist` | `Comment` | Queue artist name (dimmed) |
| `AppleMusicQueueHeader` | `Title` | "Up Next" header |
| `AppleMusicBorder` | `FloatBorder` | Window border |
| `AppleMusicNormal` | `Normal` | Normal text / background |

## Architecture

```
lua/apple-music/
├── init.lua          # Public API
├── config.lua        # Configuration management
├── player.lua        # AppleScript interface (async)
├── ui.lua            # Docked window UI
├── search.lua        # Library browsing and search
├── highlights.lua    # Theming and highlight groups
├── artwork.lua       # Album artwork management
├── cache.lua         # Persistent artwork cache
├── queue_artwork.lua # Queue thumbnails
└── kitty.lua         # Direct Kitty graphics protocol implementation
```

## Metadata Available

The plugin fetches all available track metadata from Apple Music:

- Basic: name, artist, album, duration, position
- Extended: genre, year, rating, composer, album_artist
- Stats: track/disc numbers, play count, bit rate
- Status: favorited, disliked, player state
- Artwork: album art (if available)

## Troubleshooting

### Album artwork

**Requirements**:
1. Verify you're using **Kitty terminal**: `echo $TERM` should show `xterm-kitty`
2. Artwork is enabled by default with the docked window layout

The plugin uses a custom, lightweight Kitty graphics protocol implementation that avoids the flickering and positioning issues found in image.nvim.

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

## Roadmap

### Phase 1: Queue & History (Current Focus)
- [ ] **Next tracks viewer** - Show upcoming tracks in current playlist/queue
- [ ] **Play history** - Show recently played tracks from current session
- [ ] Display in existing docked UI (scrollable list below current track)
- [ ] Navigate queue (jump to track, see position X/Y)

### Phase 2: Library Browsing ✅
- [x] **Track browser** - Searchable list of all library tracks
- [x] **Album browser** - Browse and play albums from library
- [x] **Artist browser** - Filter by artist
- [x] **Playlist browser** - Select and play existing playlists
- [x] Integration with Telescope/fzf-lua (with fallback to `vim.ui.select`)
- [ ] Use AppleScript `-s s` flag + `loadstring()` for efficient parsing (future optimization)

### Phase 3: Playlist Management
- [ ] **Create playlists** - New playlist from selection
- [ ] **Add to playlist** - Add current track or selection to playlist
- [ ] **Remove from playlist** - Delete tracks from playlists
- [ ] **Reorder tracks** - Drag/move tracks within playlists
- [ ] **Delete playlists** - Remove playlists from library

### Phase 4: Advanced Features
- [ ] **Search within library** - Filter by genre, year, composer, etc.
- [ ] **Queue builder** - Create temporary "up next" queue
- [ ] **Smart filters** - "Most played", "Recently added", "Favorited", etc.
- [ ] **Batch operations** - Favorite multiple tracks, add album to playlist
- [ ] **Playlist export** - Save playlists to file

### Potential Future Enhancements
- [ ] Mini mode (statusline/lualine integration)
- [ ] Lyrics display (if available in track metadata)
- [ ] Rating support (star ratings)
- [ ] Cross-fade settings
- [ ] Repeat mode control
- [ ] AppleScript command caching for offline query building

## Technical Notes

### Discovered Capabilities (from exploring p5quared/apple-music.nvim)

Music.app's AppleScript API supports:

**Library querying**:
```applescript
-- Returns Lua-compatible table format with -s s flag
osascript -e 'tell application "Music" to get name of playlists' -s s
osascript -e 'tell application "Music" to get album of every track' -s s
```

**Current playlist/queue**:
```applescript
tell application "Music"
  set currentPL to current playlist
  set allTracks to every track of currentPL
  -- Find current track index for next/previous tracks
end tell
```

**Playlist management**:
```applescript
-- Create
make new playlist with properties {name: "My Playlist"}

-- Add tracks
duplicate someTrack to targetPlaylist

-- Reorder
move track 1 of playlist "X" to end of playlist "X"

-- Delete
delete playlist "My Playlist"
delete track 2 of playlist "My Playlist"
```

**Search**:
```applescript
search playlist "Library" for "query" only artists
-- Search areas: all, artists, albums, composers, visible
```

## License

MIT
