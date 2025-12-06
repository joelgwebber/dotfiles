# vinyl.nvim

A music controller for Neovim with support for **Apple Music** and **Spotify**.

## Features

- **Multiple backends**: Apple Music (macOS) and Spotify (cross-platform with Premium)
- **Docked UI** with comprehensive track information
- **Album artwork** display (direct Kitty graphics protocol implementation)
- **Library browsing** with Telescope/fzf-lua integration:
  - Browse and play tracks
  - Browse and play albums
  - Browse and play by artist
  - Browse and play playlists
- **Extended metadata**:
  - Genre, Year, Composer (Apple Music)
  - Track/Disc numbers
  - Play count, Bit rate (Apple Music)
  - Favorited/Disliked status (Apple Music: ❤/💔)
  - Album artist (when different from track artist)
- **Real-time updates** with async I/O (non-blocking)
- **Playback controls** (play/pause, next/previous, shuffle)
- **Precise seeking** (±5s, ±30s with h/l/H/L)
- **Volume control** with visual indicator
- **Instant UI feedback** - optimistic updates for all actions
- **Clean, minimal docked interface**

## Requirements

- Neovim 0.8+
- **Apple Music backend**: macOS + Apple Music.app
- **Spotify backend**: Spotify Premium account + OAuth app credentials
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
  dir = vim.fn.expand('~/dotfiles/plugins/vinyl.nvim'),
  name = 'vinyl.nvim',
  -- No dependencies - direct Kitty graphics protocol implementation
  config = function()
    require('vinyl').setup({
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
    { '<leader>m<Space>', '<cmd>Vinyl play<CR>', desc = 'Music: Play/pause' },
    { '<leader>mm', '<cmd>Vinyl toggle<CR>', desc = 'Music: Toggle UI' },
    { '<leader>mn', '<cmd>Vinyl next<CR>', desc = 'Music: Next track' },
    { '<leader>mN', '<cmd>Vinyl prev<CR>', desc = 'Music: Previous track' },
    { '<leader>ms', '<cmd>Vinyl shuffle<CR>', desc = 'Music: Toggle shuffle' },
    -- Library browsing
    { '<leader>mp', '<cmd>Vinyl playlists<CR>', desc = 'Music: Browse playlists' },
    { '<leader>ma', '<cmd>Vinyl albums<CR>', desc = 'Music: Browse albums' },
    { '<leader>mt', '<cmd>Vinyl tracks<CR>', desc = 'Music: Browse tracks' },
    { '<leader>mr', '<cmd>Vinyl artists<CR>', desc = 'Music: Browse artists' },
    -- Backend management
    { '<leader>mb', '<cmd>Vinyl backend<CR>', desc = 'Music: Show backend' },
  },
}
```

## Backend Setup

The plugin supports two music backends and automatically detects which one to use based on availability. If both are available, Spotify takes precedence.

### Apple Music (macOS only)

No setup required! If you're on macOS with Apple Music installed, the plugin will work out of the box.

### Spotify

**Requirements:**
- Spotify Premium account (required for playback control)
- Spotify Developer App credentials

**Setup:**

1. **Run the login command:**
   ```vim
   :Vinyl spotify-login
   ```

2. **Create a Spotify App:**
   - Go to https://developer.spotify.com/dashboard
   - Click "Create app"
   - Fill in app details:
     - App name: "Neovim Music Controller" (or whatever you prefer)
     - App description: "Control Spotify from Neovim"
     - Redirect URI: `http://127.0.0.1:8888/callback` (Spotify requires 127.0.0.1, not localhost)
   - Check "Web API" in "Which API/SDKs are you planning to use?"
   - Accept terms and create the app
   - Note your **Client ID** and **Client Secret**

3. **Enter your credentials:**
   - Enter your Client ID when prompted
   - Enter your Client Secret when prompted
   - Enter your Redirect URI (default: `http://127.0.0.1:8888/callback`)
   - A browser will open for Spotify authorization
   - After authorizing, you'll be **automatically redirected back** - no manual copying needed!
   - The OAuth callback server handles the redirect automatically

4. **Done!** Your credentials are saved and the plugin will automatically use Spotify.

**Note:** The plugin starts a temporary HTTP server on 127.0.0.1 to catch the OAuth callback. This eliminates the need to manually copy/paste URLs.

**Logout:**
```vim
:Vinyl spotify-logout
```

**Check Authentication:**
```vim
:Vinyl spotify-status
```

**Switching Backends:**

If you have both Apple Music and Spotify configured, you can manually switch:
```vim
:Vinyl backend spotify
:Vinyl backend apple
```

**Rate Limiting:**

The Spotify backend implements smart rate limiting:
- Minimum 100ms between requests
- Automatic exponential backoff on 429 errors
- Respects `Retry-After` headers
- Adaptive polling (1-2 second intervals)

## Usage

### Commands

All functionality is available via the `:Vinyl` command with subcommand autocompletion:

**Main:**
- `:Vinyl` or `:Vinyl toggle` - Toggle UI
- `:Vinyl play` / `:Vinyl pause` - Play/pause

**Playback:**
- `:Vinyl next` - Next track
- `:Vinyl prev` - Previous track
- `:Vinyl shuffle` - Toggle shuffle

**Library browsing:**
- `:Vinyl playlists` - Browse playlists
- `:Vinyl albums` - Browse albums
- `:Vinyl tracks` - Browse tracks
- `:Vinyl artists` - Browse artists

**Backend management:**
- `:Vinyl backend` - Show current backend
- `:Vinyl backend spotify` - Switch to Spotify
- `:Vinyl backend apple` - Switch to Apple Music

**Spotify authentication:**
- `:Vinyl spotify-login` - Login to Spotify
- `:Vinyl spotify-logout` - Logout from Spotify
- `:Vinyl spotify-status` - Show Spotify auth status

**Debug:**
- `:Vinyl debug-backend` - Show backend capabilities
- `:Vinyl debug-queue` - Show queue debug info

**Tip:** Type `:Vinyl <Tab>` to see all available subcommands with autocompletion!

### Default Keymaps

Default keymaps are provided (disable with `vim.g.vinyl_no_default_keymaps = true`):

**Playback controls:**
- `<leader>m<Space>` - Play/pause
- `<leader>mm` - Toggle UI
- `<leader>mn` - Next track
- `<leader>mN` - Previous track
- `<leader>ms` - Toggle shuffle

**Library browsing:**
- `<leader>mp` - Browse playlists
- `<leader>ma` - Browse albums
- `<leader>mt` - Browse tracks
- `<leader>mr` - Browse artists

**Backend:**
- `<leader>mb` - Show current backend

### UI Keymaps (when window is open)

- `q` / `<Esc>` - Close UI
- `<Space>` - Play/pause
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
require('vinyl').setup({
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
lua/vinyl/
├── init.lua              # Public API & backend selection
├── config.lua            # Configuration management
├── backends/
│   ├── backend.lua       # Backend interface/abstract class
│   ├── apple.lua         # Apple Music backend implementation
│   └── spotify.lua       # Spotify backend implementation
├── spotify/
│   ├── auth.lua          # OAuth 2.0 flow
│   ├── api.lua           # API client with rate limiting
│   ├── state.lua         # Token storage
│   └── oauth_server.lua  # Automatic OAuth callback handler
├── player.lua            # AppleScript interface (Apple Music)
├── ui.lua                # Docked window UI (backend-agnostic)
├── search.lua            # Library browsing (Apple Music)
├── highlights.lua        # Theming and highlight groups
├── artwork.lua           # Album artwork management
├── cache.lua             # Persistent artwork cache
├── queue_artwork.lua     # Queue thumbnails
└── kitty.lua             # Direct Kitty graphics protocol implementation
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

1. Edit files in `plugins/vinyl.nvim/lua/vinyl/`
2. Reload: `:Lazy reload vinyl.nvim`
3. Reopen UI: `<leader>mu`

### Testing

Test individual components:

```lua
-- Test player state
:lua vim.print(require('vinyl.player').get_state_async(vim.print))

-- Test artwork extraction
:lua require('vinyl.player').get_artwork_async(vim.print)
```

## Roadmap

### Completed ✅
- [x] **Spotify backend support** - Full Spotify Web API integration with OAuth 2.0
- [x] **Backend abstraction** - Unified interface supporting multiple music services
- [x] **Queue display** - Show upcoming tracks with backend-specific capabilities
  - Apple Music: Shows playlist order (shuffle limitations)
  - Spotify: Shows actual playback queue (accurate with shuffle)
- [x] **Artwork support** - Album art display for both backends
  - Apple Music: File-based extraction via AppleScript
  - Spotify: URL-based download with format detection
- [x] **Library browsing** - Searchable track/album/artist/playlist browsers
  - Integration with Telescope/fzf-lua (with fallback to `vim.ui.select`)
  - Works with both Apple Music library and Spotify saved content
- [x] **Unified command structure** - `:Vinyl` command with subcommand autocompletion
- [x] **Backend capabilities system** - Declarative feature support per backend

### Phase 1: Playback Features
- [ ] **Play history** - Show recently played tracks from current session
- [ ] **Repeat mode control** - Toggle repeat modes (off/context/track)
- [ ] **Queue navigation** - Jump to specific track in queue
- [ ] **Queue position display** - Show current position (X/Y) in context

### Phase 2: Playlist Management (Apple Music only)
- [ ] **Create playlists** - New playlist from selection
- [ ] **Add to playlist** - Add current track or selection to playlist
- [ ] **Remove from playlist** - Delete tracks from playlists
- [ ] **Reorder tracks** - Move tracks within playlists
- [ ] **Delete playlists** - Remove playlists from library

### Phase 3: Advanced Features
- [ ] **Search within library** - Filter by genre, year, composer, etc.
- [ ] **Smart filters** - "Most played", "Recently added", "Favorited", etc.
- [ ] **Batch operations** - Favorite multiple tracks, add album to playlist
- [ ] **Lyrics display** - Show lyrics if available in track metadata
- [ ] **Rating support** - Star ratings (Apple Music)

### Potential Future Enhancements
- [ ] **Additional backends** - Support for more music services (YouTube Music, etc.)
- [ ] **Mini mode** - Statusline/lualine integration
- [ ] **Playlist export** - Save playlists to file (M3U, etc.)
- [ ] **Cross-platform improvements** - Better Linux/Windows support where possible
- [ ] **Performance optimizations** - AppleScript caching, parallel requests

## License

MIT
