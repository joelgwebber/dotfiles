-- Apple Music backend implementation
local Backend = require("vinyl.backends.backend")
local player = require("vinyl.backends.apple_player")
local search = require("vinyl.search")

local M = {}

---@return Backend
function M.new()
	local backend = Backend.new()
	backend.name = "apple"
	backend.display_name = "Apple Music"

	-- Declare capabilities
	backend.capabilities = {
		playback_control = true,
		volume_control = true,
		queue_access = true,
		queue_shuffle_accurate = false, -- Can only show playlist order, not actual shuffle queue
		library_browsing = true,
		playlist_access = true,
		seek = true,
		artwork = true,
		streaming_queue = false, -- Only works for tracks in local library
	}

	-- Check if Apple Music is available (macOS only)
	function backend.available()
		if vim.fn.has("mac") ~= 1 then
			return false
		end

		-- Check if Music.app is running or can be launched
		local script = [[
      try
        tell application "Music" to get name
        return "true"
      on error
        return "false"
      end try
    ]]
		local result = vim.fn.system({ "osascript", "-e", script })
		return vim.trim(result) == "true"
	end

	-- Initialize backend
	function backend.init(config)
		if not backend.available() then
			vim.notify("Apple Music is only available on macOS", vim.log.levels.ERROR)
			return false
		end
		return true
	end

	-- Convert player state to backend state format
	local function convert_state(player_state)
		if not player_state or not player_state.player_state then
			return {
				playing = false,
				track_name = nil,
				artist = nil,
				album = nil,
			}
		end

		return {
			playing = player_state.player_state == "playing",
			track_name = player_state.track_name,
			artist = player_state.artist,
			album = player_state.album,
			album_artist = player_state.album_artist,
			duration = player_state.duration,
			position = player_state.position,
			volume = player_state.volume,
			shuffle = player_state.shuffle_enabled,
			repeat_mode = player_state.repeat_mode or "off",
			genre = player_state.genre,
			year = player_state.year,
			composer = player_state.composer,
			track_number = player_state.track_number,
			disc_number = player_state.disc_number,
			play_count = player_state.played_count,
			bit_rate = player_state.bit_rate,
			favorited = player_state.favorited,
			disliked = player_state.disliked,
			artwork_count = player_state.artwork_count, -- Needed for artwork display
		}
	end

	-- Get current playback state
	function backend.get_state_async(callback)
		player.get_state_async(function(state)
			callback(convert_state(state), nil)
		end)
	end

	-- Playback controls
	function backend.play_pause(callback)
		player.play_pause()
		if callback then
			callback(true, nil)
		end
	end

	function backend.next_track(callback)
		player.next_track()
		if callback then
			callback(true, nil)
		end
	end

	function backend.previous_track(callback)
		player.previous_track()
		if callback then
			callback(true, nil)
		end
	end

	function backend.seek(position_ms, callback)
		local position_seconds = position_ms / 1000
		player.set_position(position_seconds)
		if callback then
			callback(true, nil)
		end
	end

	function backend.set_volume(volume, callback)
		player.set_volume(volume)
		if callback then
			callback(true, nil)
		end
	end

	function backend.increase_volume(callback)
		player.increase_volume()
		if callback then
			callback(true, nil)
		end
	end

	function backend.decrease_volume(callback)
		player.decrease_volume()
		if callback then
			callback(true, nil)
		end
	end

	function backend.toggle_shuffle(callback)
		player.toggle_shuffle()
		if callback then
			callback(true, nil)
		end
	end

	function backend.toggle_repeat(callback)
		-- Apple Music doesn't expose repeat control via AppleScript easily
		-- This would need additional implementation
		if callback then
			callback(false, "Repeat toggle not yet implemented for Apple Music")
		end
	end

	-- Library browsing (delegate to search module)
	function backend.get_library_tracks_async(callback)
		search.get_library_tracks_async(function(tracks, err)
			if err then
				callback(nil, err)
				return
			end

			-- Convert to backend format
			local converted = {}
			for _, track in ipairs(tracks) do
				table.insert(converted, {
					id = track.persistent_id,
					name = track.name,
					artist = track.artist,
					album = track.album,
					duration = 0, -- Not available in search module
				})
			end
			callback(converted, nil)
		end)
	end

	function backend.get_library_albums_async(callback)
		search.get_library_albums_async(function(albums, err)
			if err then
				callback(nil, err)
				return
			end

			-- Convert to backend format
			local converted = {}
			for _, album in ipairs(albums) do
				table.insert(converted, {
					id = album.album .. "|" .. album.artist, -- Compound ID
					name = album.album,
					artist = album.artist,
					track_count = 0, -- Not available in search module
				})
			end
			callback(converted, nil)
		end)
	end

	function backend.get_library_artists_async(callback)
		search.get_library_artists_async(function(artists, err)
			if err then
				callback(nil, err)
				return
			end

			-- Convert to backend format
			local converted = {}
			for _, artist in ipairs(artists) do
				table.insert(converted, {
					id = artist,
					name = artist,
				})
			end
			callback(converted, nil)
		end)
	end

	function backend.get_playlists_async(callback)
		search.get_playlists_async(function(playlists, err)
			if err then
				callback(nil, err)
				return
			end

			-- Convert to backend format
			-- search.get_playlists_async returns {name, persistent_id}
			local converted = {}
			for _, playlist in ipairs(playlists) do
				table.insert(converted, {
					id = playlist.persistent_id,
					name = playlist.name,
					track_count = 0, -- Not available in search module
				})
			end
			callback(converted, nil)
		end)
	end

	-- Playback start (delegate to search module)
	function backend.play_track(track_id, callback)
		search.play_track(track_id, function(success, msg)
			if callback then
				callback(success, success and nil or msg)
			end
		end)
	end

	function backend.play_album(album_id, callback)
		-- album_id format: "album|artist"
		local parts = vim.split(album_id, "|")
		if #parts < 2 then
			if callback then
				callback(false, "Invalid album ID format")
			end
			return
		end

		search.play_album(parts[1], parts[2], function(success, msg)
			if callback then
				callback(success, success and nil or msg)
			end
		end)
	end

	function backend.play_artist(artist_id, callback)
		search.play_artist(artist_id, function(success, msg)
			if callback then
				callback(success, success and nil or msg)
			end
		end)
	end

	function backend.play_playlist(playlist_id, callback)
		search.play_playlist(playlist_id, function(success, msg)
			if callback then
				callback(success, success and nil or msg)
			end
		end)
	end

	-- Artwork
	function backend.get_artwork_async(callback)
		player.get_artwork_async(function(data, err)
			callback(data, err)
		end)
	end

	-- Queue
	function backend.get_queue_async(callback)
		player.get_queue_async(function(queue, err)
			if err or not queue then
				if callback then
					callback(nil, err)
				end
				return
			end

			-- Pass through queue with all metadata intact
			-- UI expects: current_index, total_tracks, shuffle_enabled, upcoming_tracks
			if callback then
				callback(queue, nil)
			end
		end)
	end

	-- Apple Music specific: Get artwork for a specific album by name
	-- This is needed for preloading queue artwork
	-- Not in the base Backend interface as it's Apple Music specific
	function backend.get_album_artwork_async(album_name, callback)
		player.get_album_artwork_async(album_name, callback)
	end

	return backend
end

return M
