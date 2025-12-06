-- Backend interface/abstract class
-- All music backends (Apple Music, Spotify, etc.) must implement these methods
local M = {}

---@class BackendState
---@field playing boolean Whether playback is active
---@field track_name string? Current track name
---@field artist string? Current artist
---@field album string? Current album
---@field album_artist string? Album artist (if different from track artist)
---@field duration number? Track duration in seconds
---@field position number? Current position in seconds
---@field volume number? Volume (0-100)
---@field shuffle boolean? Shuffle enabled
---@field repeat_mode string? "off"|"one"|"all"
---@field genre string? Track genre
---@field year number? Release year
---@field composer string? Composer
---@field track_number number? Track number
---@field disc_number number? Disc number
---@field play_count number? Play count
---@field bit_rate number? Bit rate (kbps)
---@field favorited boolean? User has favorited
---@field disliked boolean? User has disliked
---@field track_id string? Backend-specific track ID
---@field album_id string? Backend-specific album ID
---@field artist_id string? Backend-specific artist ID
---@field playlist_id string? Backend-specific playlist ID
---@field artwork_url string? URL to artwork (Spotify provides URLs)
---@field artwork_count number? Number of artworks available (Apple Music uses this)

---@class BackendTrack
---@field id string Backend-specific track ID
---@field name string Track name
---@field artist string Artist name
---@field album string Album name
---@field duration number? Duration in seconds

---@class BackendAlbum
---@field id string Backend-specific album ID
---@field name string Album name
---@field artist string Artist name
---@field track_count number? Number of tracks

---@class BackendArtist
---@field id string Backend-specific artist ID
---@field name string Artist name

---@class BackendPlaylist
---@field id string Backend-specific playlist ID
---@field name string Playlist name
---@field track_count number? Number of tracks

---@class BackendQueueTrack
---@field name string Track name
---@field artist string Artist name
---@field album string? Album name

---@class BackendQueue
---@field current_index number? Current track position in queue (1-indexed)
---@field total_tracks number? Total tracks in current context
---@field shuffle_enabled boolean Whether shuffle is enabled
---@field upcoming_tracks BackendQueueTrack[] List of upcoming tracks

---@class BackendCapabilities
---@field playback_control boolean Can control playback (play/pause/skip)
---@field volume_control boolean Can control volume
---@field queue_access boolean Can access playback queue
---@field queue_shuffle_accurate boolean Queue is accurate when shuffle is enabled
---@field library_browsing boolean Can browse user's library
---@field playlist_access boolean Can access user playlists
---@field seek boolean Can seek within tracks
---@field artwork boolean Can fetch artwork
---@field streaming_queue boolean Can show queue for streaming (non-library) tracks

---@class Backend
---@field name string Backend name (e.g., "apple", "spotify")
---@field display_name string Human-readable name (e.g., "Apple Music", "Spotify")
---@field capabilities BackendCapabilities? Optional capabilities declaration
---@field available fun(): boolean Check if backend is available
---@field init fun(config: table): boolean Initialize backend with configuration
---@field get_state_async fun(callback: fun(state: BackendState?, error: string?)) Get current playback state
---@field play_pause fun(callback: fun(success: boolean, error: string?)?) Toggle play/pause
---@field next_track fun(callback: fun(success: boolean, error: string?)?) Skip to next track
---@field previous_track fun(callback: fun(success: boolean, error: string?)?) Skip to previous track
---@field seek fun(position_ms: number, callback: fun(success: boolean, error: string?)?) Seek to position
---@field set_volume fun(volume: number, callback: fun(success: boolean, error: string?)?) Set volume (0-100)
---@field increase_volume fun(callback: fun(success: boolean, error: string?)?) Increase volume
---@field decrease_volume fun(callback: fun(success: boolean, error: string?)?) Decrease volume
---@field toggle_shuffle fun(callback: fun(success: boolean, error: string?)?) Toggle shuffle
---@field toggle_repeat fun(callback: fun(success: boolean, error: string?)?) Toggle repeat mode
---@field get_library_tracks_async fun(callback: fun(tracks: BackendTrack[]?, error: string?)) Get all library tracks
---@field get_library_albums_async fun(callback: fun(albums: BackendAlbum[]?, error: string?)) Get all library albums
---@field get_library_artists_async fun(callback: fun(artists: BackendArtist[]?, error: string?)) Get all library artists
---@field get_playlists_async fun(callback: fun(playlists: BackendPlaylist[]?, error: string?)) Get all playlists
---@field play_track fun(track_id: string, callback: fun(success: boolean, error: string?)?) Play specific track
---@field play_album fun(album_id: string, callback: fun(success: boolean, error: string?)?) Play specific album
---@field play_artist fun(artist_id: string, callback: fun(success: boolean, error: string?)?) Play tracks by artist
---@field play_playlist fun(playlist_id: string, callback: fun(success: boolean, error: string?)?) Play specific playlist
---@field get_artwork_async fun(callback: fun(data: any?, error: string?)) Get current track artwork (format varies by backend)
---@field get_queue_async fun(callback: fun(queue: BackendQueue?, error: string?)?) Get queue info and upcoming tracks
---
--- IMPORTANT LIMITATIONS:
--- - Apple Music: Can only access playlist/album order, NOT actual playback queue when shuffle is on
--- - Spotify: Can access actual playback queue via API
--- - Both: Queue may be unavailable for streaming tracks not in library (Apple Music)
--- - When shuffle is enabled, upcoming_tracks may be empty or show playlist order (not actual queue)

--- Create a new backend instance
--- Backends should override these methods with their implementations
---@return Backend
function M.new()
	local backend = {
		name = "base",
		display_name = "Base Backend",
	}

	-- Check if backend is available (e.g., Apple Music on macOS, Spotify with auth)
	function backend.available()
		error("Backend.available() must be implemented")
	end

	-- Initialize backend with configuration
	function backend.init(config)
		error("Backend.init() must be implemented")
	end

	-- Playback state
	function backend.get_state_async(callback)
		error("Backend.get_state_async() must be implemented")
	end

	-- Playback controls
	function backend.play_pause(callback)
		error("Backend.play_pause() must be implemented")
	end

	function backend.next_track(callback)
		error("Backend.next_track() must be implemented")
	end

	function backend.previous_track(callback)
		error("Backend.previous_track() must be implemented")
	end

	function backend.seek(position_ms, callback)
		error("Backend.seek() must be implemented")
	end

	function backend.set_volume(volume, callback)
		error("Backend.set_volume() must be implemented")
	end

	function backend.increase_volume(callback)
		error("Backend.increase_volume() must be implemented")
	end

	function backend.decrease_volume(callback)
		error("Backend.decrease_volume() must be implemented")
	end

	function backend.toggle_shuffle(callback)
		error("Backend.toggle_shuffle() must be implemented")
	end

	function backend.toggle_repeat(callback)
		error("Backend.toggle_repeat() must be implemented")
	end

	-- Library browsing
	function backend.get_library_tracks_async(callback)
		error("Backend.get_library_tracks_async() must be implemented")
	end

	function backend.get_library_albums_async(callback)
		error("Backend.get_library_albums_async() must be implemented")
	end

	function backend.get_library_artists_async(callback)
		error("Backend.get_library_artists_async() must be implemented")
	end

	function backend.get_playlists_async(callback)
		error("Backend.get_playlists_async() must be implemented")
	end

	-- Playback start
	function backend.play_track(track_id, callback)
		error("Backend.play_track() must be implemented")
	end

	function backend.play_album(album_id, callback)
		error("Backend.play_album() must be implemented")
	end

	function backend.play_artist(artist_id, callback)
		error("Backend.play_artist() must be implemented")
	end

	function backend.play_playlist(playlist_id, callback)
		error("Backend.play_playlist() must be implemented")
	end

	-- Artwork
	function backend.get_artwork_async(callback)
		error("Backend.get_artwork_async() must be implemented")
	end

	-- Queue
	function backend.get_queue_async(callback)
		-- Optional - some backends may not support queue
		if callback then
			callback(nil, "Queue not supported by this backend")
		end
	end

	return backend
end

return M
