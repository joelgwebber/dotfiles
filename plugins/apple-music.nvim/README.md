# apple-music.nvim

A performant, feature-rich music controller for Neovim with support for **Apple Music** and **Spotify**.

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
    { '<leader>m<Space>', '<cmd>MusicPlay<CR>', desc = 'Music: Play/pause' },
    { '<leader>mm', '<cmd>Music<CR>', desc = 'Music: Toggle UI' },
    { '<leader>mn', '<cmd>MusicNext<CR>', desc = 'Music: Next track' },
    { '<leader>mN', '<cmd>MusicPrev<CR>', desc = 'Music: Previous track' },
    { '<leader>ms', '<cmd>MusicShuffle<CR>', desc = 'Music: Toggle shuffle' },
    -- Library browsing
    { '<leader>mp', '<cmd>MusicPlaylists<CR>', desc = 'Music: Browse playlists' },
    { '<leader>ma', '<cmd>MusicAlbums<CR>', desc = 'Music: Browse albums' },
    { '<leader>mt', '<cmd>MusicTracks<CR>', desc = 'Music: Browse tracks' },
    { '<leader>mr', '<cmd>MusicArtists<CR>', desc = 'Music: Browse artists' },
    -- Backend management
    { '<leader>mb', '<cmd>MusicBackend<CR>', desc = 'Music: Show backend' },
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
   :MusicSpotifyLogin
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
:MusicSpotifyLogout
```

**Check Authentication:**
```vim
:MusicSpotifyStatus
```

**Switching Backends:**

If you have both Apple Music and Spotify configured, you can manually switch:
```vim
:MusicBackend spotify
:MusicBackend apple_music
```

**Rate Limiting:**

The Spotify backend implements smart rate limiting:
- Minimum 100ms between requests
- Automatic exponential backoff on 429 errors
- Respects `Retry-After` headers
- Adaptive polling (1-2 second intervals)

## Usage

### Commands

All functionality is available via vim commands:

**Main:**
- `:Music` - Toggle UI
- `:MusicPlay` - Play/pause

**Playback:**
- `:MusicNext` - Next track
- `:MusicPrev` - Previous track
- `:MusicShuffle` - Toggle shuffle

**Library browsing:**
- `:MusicPlaylists` - Browse playlists
- `:MusicAlbums` - Browse albums
- `:MusicTracks` - Browse tracks
- `:MusicArtists` - Browse artists

**Backend management:**
- `:MusicBackend` - Show current backend
- `:MusicBackend spotify` - Switch to Spotify
- `:MusicBackend apple_music` - Switch to Apple Music
- `:MusicSpotifyLogin` - Login to Spotify
- `:MusicSpotifyLogout` - Logout from Spotify
- `:MusicSpotifyStatus` - Show Spotify auth status

**Debug:**
- `:MusicDebugBackend` - Show backend capabilities
- `:MusicDebugQueue` - Show queue debug info

### Default Keymaps

Default keymaps are provided (disable with `vim.g.apple_music_no_default_keymaps = true`):

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
├── init.lua              # Public API & backend selection
├── config.lua            # Configuration management
├── backends/
│   ├── backend.lua       # Backend interface/abstract class
│   ├── apple_music.lua   # Apple Music backend implementation
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
