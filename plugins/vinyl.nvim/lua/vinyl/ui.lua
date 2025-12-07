local config = require("vinyl.config")
local artwork = require("vinyl.artwork")
local queue_artwork = require("vinyl.queue_artwork")
local artwork_preloader = require("vinyl.artwork_preloader")
local state_cache = require("vinyl.state_cache")
local hl = require("vinyl.highlights")
local debouncer = require("vinyl.debouncer")

local M = {}

-- Get backend from main module
local function get_backend()
	local main = require("vinyl")
	return main.get_backend()
end

M.buf = nil
M.win = nil
M.timer = nil
M.last_state = {} -- Cache state for volume controls
M.last_queue = nil -- Cache queue data
M.last_track_id = nil -- Track ID to detect track changes
M.resize_group = nil -- Autocmd group for resize handling
M.track_changing = false -- Flag to prevent stale renders during track transitions
M.last_play_pause_time = 0 -- Timestamp to prevent rapid play/pause calls
M.last_volume_time = 0 -- Timestamp to prevent rapid volume calls
M.optimistic_update_until = 0 -- Timestamp until which to ignore periodic refreshes

local function format_time(seconds)
	if not seconds then
		return "0:00"
	end
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

local function format_progress_bar(position, duration, width)
	if not position or not duration or duration == 0 then
		return string.rep("─", width)
	end

	local progress = position / duration
	local filled = math.floor(progress * width)
	local bar = string.rep("━", filled) .. string.rep("─", width - filled)
	return bar
end

local function format_metadata_line(state)
	local parts = {}

	-- Genre
	if state.genre then
		table.insert(parts, state.genre)
	end

	-- Year
	if state.year and state.year > 0 then
		table.insert(parts, tostring(state.year))
	end

	-- Track/Disc numbers
	if state.track_number and state.track_number > 0 then
		if state.track_count and state.track_count > 0 then
			table.insert(parts, string.format("Track %d/%d", state.track_number, state.track_count))
		else
			table.insert(parts, string.format("Track %d", state.track_number))
		end
	end

	if state.disc_number and state.disc_number > 1 then
		if state.disc_count and state.disc_count > 0 then
			table.insert(parts, string.format("Disc %d/%d", state.disc_number, state.disc_count))
		end
	end

	return table.concat(parts, " • ")
end

local function format_stats_line(state)
	local parts = {}

	-- Love/hate status
	if state.favorited then
		table.insert(parts, "❤")
	elseif state.disliked then
		table.insert(parts, "💔")
	end

	-- Play count
	if state.played_count and state.played_count > 0 then
		table.insert(
			parts,
			string.format("Played %d time%s", state.played_count, state.played_count == 1 and "" or "s")
		)
	end

	-- Bit rate
	if state.bit_rate and state.bit_rate > 0 then
		table.insert(parts, string.format("%d kbps", state.bit_rate))
	end

	return table.concat(parts, " • ")
end

-- Helper function to center text within a given width
local function center_text(text, width)
	local text_len = vim.fn.strdisplaywidth(text)
	if text_len >= width then
		-- Truncate on the right if too long (keep left edge visible)
		return vim.fn.strcharpart(text, 0, width)
	end
	local padding = math.floor((width - text_len) / 2)
	return string.rep(" ", padding) .. text
end

-- Helper function to create a centered line with 2ch margins
local function centered_line(text, width)
	local usable_width = width - 4 -- 2ch margin on each side
	local centered = center_text(text, usable_width)
	return "  " .. centered
end

-- Helper function for queue items with space for 4x2 artwork on the left
-- Text starts at column 7 (2ch margin + 4ch image + 1ch spacing)
local function queue_line_with_artwork(text, width)
	local text_len = vim.fn.strdisplaywidth(text)
	local available_width = width - 7 -- Space after image area

	if text_len > available_width then
		text = vim.fn.strcharpart(text, 0, available_width)
	end

	return "  " .. "    " .. " " .. text -- 2ch margin + 4ch image placeholder + 1ch spacing
end

-- Helper function to create a centered placeholder box
local function create_placeholder_box(win_width, box_width, box_height)
	local lines = {}
	local centered_col_offset = math.floor((win_width - box_width) / 2)
	local padding = string.rep(" ", centered_col_offset)

	-- Top border
	table.insert(lines, padding .. "┌" .. string.rep("─", box_width - 2) .. "┐")

	-- Middle rows (empty)
	for i = 2, box_height - 1 do
		table.insert(lines, padding .. "│" .. string.rep(" ", box_width - 2) .. "│")
	end

	-- Bottom border
	table.insert(lines, padding .. "└" .. string.rep("─", box_width - 2) .. "┘")

	-- Add spacing line after box
	table.insert(lines, "")

	return lines
end

-- Render the UI with the given state (no AppleScript call)
-- Optional queue parameter to render queue section
local function render_with_state(state, queue)
	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		return
	end

	-- Check if window still exists (user might have closed it)
	if not M.win or not vim.api.nvim_win_is_valid(M.win) then
		return
	end

	-- Get current window width dynamically
	local win_width = vim.api.nvim_win_get_width(M.win)
	local usable_width = win_width - 4 -- 2ch margin on each side

	-- Calculate dynamic artwork size (do this early so we can reserve space)
	-- Use 80% of window width, clamped to configured max size
	local artwork_width_chars = math.floor(win_width * 0.8)
	artwork_width_chars = math.max(10, math.min(artwork_width_chars, config.options.artwork.max_width_chars))

	-- Character cells are typically ~2:1 (height:width), so use half as many rows as columns
	-- to get a square image in pixels (e.g., 40 cols x 20 rows ≈ 320x320 pixels)
	local artwork_height_chars = math.floor(artwork_width_chars / 2)
	artwork_height_chars = math.min(artwork_height_chars, config.options.artwork.max_height_chars)

	local lines = {}
	local highlights = {} -- Track { line, col_start, col_end, hl_group }

	-- Reserve space at the TOP for artwork (if enabled)
	-- Always reserve space to prevent text jumping when loading/changing tracks
	if config.options.artwork.enabled then
		-- Check if artwork is available (either as Apple Music artwork_count or Spotify URL)
		local has_artwork = (state.artwork_count and state.artwork_count > 0) or state.artwork_url
		if has_artwork then
			-- Reserve empty space for actual artwork (will be displayed via extmarks)
			for i = 1, artwork_height_chars + 1 do -- +1 for spacing
				table.insert(lines, "")
			end
		else
			-- Show placeholder box when no artwork available
			local box_lines = create_placeholder_box(win_width, artwork_width_chars, artwork_height_chars)
			for _, line in ipairs(box_lines) do
				table.insert(lines, line)
			end
		end
	end

	if not state.playing or not state.track_name then
		table.insert(lines, "")
		table.insert(lines, centered_line("Music Player", win_width))
		table.insert(lines, "")
		table.insert(lines, centered_line("No track playing", win_width))
		table.insert(lines, "")
	else
		local player_icon = state.playing and "▶" or "⏸"

		-- Track name with player icon
		table.insert(lines, "")
		table.insert(
			lines,
			centered_line(string.format("%s  %s", player_icon, state.track_name or "Unknown"), win_width)
		)
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Title") })

		-- Artist
		local artist_display = state.artist or "Unknown"
		if state.album_artist and state.album_artist ~= state.artist then
			artist_display = string.format("%s (Album: %s)", state.artist, state.album_artist)
		end
		table.insert(lines, centered_line(artist_display, win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Artist") })

		-- Album
		table.insert(lines, centered_line(state.album or "Unknown Album", win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Album") })

		-- Metadata line (genre, year, track/disc numbers)
		local metadata = format_metadata_line(state)
		if metadata ~= "" then
			table.insert(lines, centered_line(metadata, win_width))
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Label") })
		end

		table.insert(lines, "")

		-- Progress bar (scales with window width)
		local progress_bar = format_progress_bar(state.position, state.duration, usable_width)
		table.insert(lines, "  " .. progress_bar)

		-- Time display
		local time_display = string.format("%s / %s", format_time(state.position), format_time(state.duration))
		table.insert(lines, centered_line(time_display, win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Time") })

		-- Stats line (favorite, play count, bit rate)
		local stats = format_stats_line(state)
		if stats ~= "" then
			table.insert(lines, centered_line(stats, win_width))
		end

		table.insert(lines, "")

		-- Volume
		if state.volume then
			local volume_width = math.min(20, usable_width - 12) -- Leave space for "Volume: " and " XX%"
			local volume_filled = math.floor((state.volume / 100) * volume_width)
			local volume_bar = string.rep("━", volume_filled) .. string.rep("─", volume_width - volume_filled)
			local volume_display = string.format("Volume: %s %d%%", volume_bar, state.volume)
			table.insert(lines, centered_line(volume_display, win_width))
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Volume") })
		end

		table.insert(lines, "")
	end

	-- Queue section (upcoming tracks)
	local queue_tracks_to_render = {} -- Track which tracks need artwork

	if queue then
		table.insert(lines, "")
		table.insert(
			lines,
			centered_line(
				"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
				win_width
			)
		)
		table.insert(lines, "")

		-- Show queue position
		if queue.current_index and queue.total_tracks then
			local position_text = string.format("Queue: %d/%d", queue.current_index, queue.total_tracks)
			table.insert(lines, centered_line(position_text, win_width))
			table.insert(lines, "")
		end

		-- Check if shuffle is enabled and backend can't show accurate shuffle queue
		local backend = require("vinyl").get_backend()
		local show_shuffle_message = queue.shuffle_enabled
			and backend
			and backend.capabilities
			and backend.capabilities.queue_shuffle_accurate == false

		if show_shuffle_message then
			-- Shuffle is on and backend can't show accurate queue (Apple Music)
			table.insert(lines, centered_line("🔀 Shuffle enabled", win_width))
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("Shuffle") })
			table.insert(lines, "")
		elseif queue.upcoming_tracks and #queue.upcoming_tracks > 0 then
			-- Render upcoming tracks (2 lines per track with artwork + blank line)
			for i, track in ipairs(queue.upcoming_tracks) do
				-- Save the 1-indexed line number where track name will be inserted
				-- This aligns the top of the 4x2 thumbnail with the track name
				table.insert(queue_tracks_to_render, {
					album = track.album,
					artwork_url = track.artwork_url, -- Spotify provides URLs, Apple Music does not
					line = #lines + 1, -- 1-indexed line number for display_image
				})

				table.insert(lines, queue_line_with_artwork(track.name, win_width))
				table.insert(
					highlights,
					{ line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("QueueTrack") }
				)
				table.insert(lines, queue_line_with_artwork(track.artist, win_width))
				table.insert(
					highlights,
					{ line = #lines - 1, col_start = 0, col_end = -1, group = hl.get("QueueArtist") }
				)

				-- Blank line between tracks (but not after the last one)
				if i < #queue.upcoming_tracks then
					table.insert(lines, "")
				end
			end

			table.insert(lines, "")
		end
	end

	-- IMPORTANT: Clear artwork cache before nvim_buf_set_lines
	-- nvim_buf_set_lines(0, -1) destroys all extmarks, so we need to force recreation
	local kitty = require("vinyl.kitty")
	kitty.last_display[M.buf] = {} -- Clear display cache for this buffer

	vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)

	-- Apply syntax highlighting (do this before making buffer non-modifiable)
	for _, hl_info in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(
			M.buf,
			-1, -- namespace (0 = default, -1 = no namespace)
			hl_info.group,
			hl_info.line,
			hl_info.col_start,
			hl_info.col_end
		)
	end

	vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

	-- Display artwork if enabled and available (at the TOP)
	if config.options.artwork.enabled then
		-- Check if artwork is available (Apple Music has artwork_count, Spotify has artwork_url)
		-- IMPORTANT: Check for vim.NIL which is truthy but represents JSON null
		local has_artwork = (state.artwork_count and state.artwork_count > 0)
			or (state.artwork_url and state.artwork_url ~= vim.NIL)
		if has_artwork and state.album and state.album ~= "" and not M.track_changing then
			-- Calculate centered column position (size already calculated above)
			local centered_col = math.floor((win_width - artwork_width_chars) / 2) + 1 -- 1-indexed

			-- Prepare artwork data to pass to display function
			-- This avoids redundant backend calls - we already have the URL/path from state!
			local artwork_data = nil
			if state.artwork_url and state.artwork_url ~= vim.NIL then
				-- Spotify backend provides URL
				artwork_data = { url = state.artwork_url }
			end
			-- For Apple Music, artwork_data is nil and display() will fetch via backend

			-- Display artwork for both Apple Music and Spotify
			-- Album name is used for caching (more efficient than per-track)
			artwork.display(
				M.buf,
				2,
				centered_col,
				state.album,
				artwork_width_chars,
				artwork_height_chars,
				artwork_data
			)
		end
		-- Note: Don't clear artwork here when no artwork!
		-- That can happen during brief player state queries.
		-- Let artwork.lua manage its own state. Only clear when window closes.

		-- Display queue artwork (4x2 images on the left, top-aligned with track names)
		if queue_tracks_to_render and #queue_tracks_to_render > 0 then
			for _, track_info in ipairs(queue_tracks_to_render) do
				if track_info.album and track_info.album ~= "" then
					-- Prepare artwork data (Spotify provides URLs, Apple Music does not)
					local artwork_data = nil
					if track_info.artwork_url and track_info.artwork_url ~= vim.NIL then
						artwork_data = { url = track_info.artwork_url }
					end

					-- Display 4x2 artwork at column 2, with 2ch left margin
					-- track_info.line is 1-indexed (line number in editor)
					queue_artwork.display_album_artwork(
						track_info.album,
						M.buf,
						track_info.line, -- 1-indexed row where track name starts
						2, -- Column (0-indexed, after 2ch margin)
						artwork_data, -- Artwork data from queue
						nil -- No callback needed
					)
				end
			end
		end
	end
end

-- Fetch state from backend and render
local function render_ui()
	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		return
	end

	-- Skip periodic refreshes during optimistic update window
	-- This prevents stale backend state from overriding optimistic updates
	local now = vim.loop.hrtime() / 1000000
	if now < M.optimistic_update_until then
		return
	end

	local backend = get_backend()
	if not backend then
		return
	end

	-- Detect if we need to fetch queue (track changed or missing)
	-- Do this check before fetching state to enable parallel fetching
	local need_queue_fetch = false
	local current_track_id_preview = nil

	-- Quick preview check using cached state to decide if we need queue
	if M.last_state then
		if M.last_state.track_id then
			current_track_id_preview = tostring(M.last_state.track_id)
		else
			current_track_id_preview = (M.last_state.track_name or "") .. "::" .. (M.last_state.album or "")
		end
	end
	need_queue_fetch = (M.last_queue == nil)
		or (M.last_track_id and M.last_track_id ~= current_track_id_preview)
		or M.track_changing -- Always fetch queue during track transitions

	-- Parallel fetch optimization: fetch state and queue simultaneously when both needed
	if need_queue_fetch then
		local state_result, queue_result = nil, nil
		local state_done, queue_done = false, false

		-- Helper to render when both complete
		local function try_render()
			if state_done and queue_done then
				if state_result then
					M.last_state = state_result
					-- Save to persistent cache for next startup (optimization)
					state_cache.save_state(state_result)


					-- Update track ID after state fetch
					local current_track_id
					if state_result.track_id then
						current_track_id = tostring(state_result.track_id)
					else
						current_track_id = (state_result.track_name or "") .. "::" .. (state_result.album or "")
					end

					if M.last_track_id ~= current_track_id then
						M.last_track_id = current_track_id


					-- Clear track changing flag only if we got a different track than we were transitioning from
					if M.track_changing and M.changing_from_track_id and current_track_id ~= M.changing_from_track_id then
						M.track_changing = false
						M.changing_from_track_id = nil
					end
					end

					M.last_queue = queue_result -- May be nil if queue fetch failed

				-- Preload next track's artwork in background (non-blocking optimization)
				if queue_result and queue_result.upcoming_tracks then
					artwork_preloader.preload_next_track(queue_result)
				end

					render_with_state(state_result, queue_result)
				end
			end
		end

		-- Fetch state (async, non-blocking)
		backend.get_state_async(function(state, err)
			state_result = (err or not state) and nil or state
			state_done = true
			try_render()
		end)

		-- Fetch queue in parallel (async, non-blocking)
		backend.get_queue_async(function(queue, queue_err)
			queue_result = (queue_err or not queue) and nil or queue
			queue_done = true
			try_render()
		end)
	else
		-- Simple state fetch only (queue is cached and still valid)
		backend.get_state_async(function(state, err)
			if err or not state then
				return
			end

			-- Cache state for volume controls and resize handling
			M.last_state = state
			-- Save to persistent cache (optimization)
			state_cache.save_state(state)


			-- Detect track changes to update track ID cache
			local current_track_id
			if state.track_id then
				current_track_id = tostring(state.track_id)
			else
				current_track_id = (state.track_name or "") .. "::" .. (state.album or "")
			end

			if M.last_track_id ~= current_track_id then
				M.last_track_id = current_track_id
			end

			-- Clear track changing flag only if we got a different track than we were transitioning from
			if M.track_changing and M.changing_from_track_id and current_track_id ~= M.changing_from_track_id then
				M.track_changing = false
				M.changing_from_track_id = nil
			end

			-- Use cached queue
			render_with_state(state, M.last_queue)
		end)
	end
end

function M.toggle()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		M.close()
	else
		M.open()
	end
end
-- Helper function to set up buffer keymaps (called once per buffer)
local function setup_buffer_keymaps(buf)
	vim.api.nvim_buf_set_keymap(buf, "n", "q", ':lua require("vinyl.ui").close()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ':lua require("vinyl.ui").close()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "<Space>", ':lua require("vinyl.ui").action_play_pause()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "n", ':lua require("vinyl.ui").action_next_track()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "N", ':lua require("vinyl.ui").action_previous_track()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "=", ':lua require("vinyl.ui").action_increase_volume()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "-", ':lua require("vinyl.ui").action_decrease_volume()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "s", ':lua require("vinyl.ui").action_toggle_shuffle()<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "h", ':lua require("vinyl.ui").action_seek_backward(5)<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "l", ':lua require("vinyl.ui").action_seek_forward(5)<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "H", ':lua require("vinyl.ui").action_seek_backward(30)<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "L", ':lua require("vinyl.ui").action_seek_forward(30)<CR>', { noremap = true, silent = true })
	vim.api.nvim_buf_set_keymap(buf, "n", "?", ':lua require("vinyl.ui").show_help()<CR>', { noremap = true, silent = true })
end


function M.open()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_set_current_win(M.win)
		return
	end

	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		M.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(M.buf, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(M.buf, "filetype", "vinyl")

		-- Set up keymaps once when buffer is created
		setup_buffer_keymaps(M.buf)
	end

	local width = config.options.window.width

	-- Create a vertical split on the right
	vim.cmd("botright vsplit")
	M.win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(M.win, M.buf)

	-- Set window width
	vim.api.nvim_win_set_width(M.win, width)

	-- Window options for cleaner appearance
	vim.api.nvim_win_set_option(M.win, "number", false)
	vim.api.nvim_win_set_option(M.win, "relativenumber", false)
	vim.api.nvim_win_set_option(M.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(M.win, "wrap", false)
	vim.api.nvim_win_set_option(M.win, "conceallevel", 0) -- Don't conceal placeholders!
	vim.api.nvim_win_set_option(M.win, "winfixwidth", true) -- Dock behavior - don't resize when balancing splits

	-- Load cached state for instant first render (optimization)
	local cached = state_cache.load_state(3600) -- Load if less than 1 hour old
	if cached and cached.state then
		M.last_state = cached.state
		-- Render immediately with cached state (instant startup!)
		render_with_state(cached.state, nil)
		-- Note: render_ui() below will fetch fresh data and update
	end

	render_ui()

	if not M.timer then
		M.timer = vim.loop.new_timer()
		M.timer:start(
			0,
			config.options.update_interval,
			vim.schedule_wrap(function()
				if M.win and vim.api.nvim_win_is_valid(M.win) then
					render_ui()
				end
			end)
		)
	end
end

function M.show_help()
	vim.notify([[
Vinyl Music Player - Keyboard Shortcuts:

<Space>  Play/Pause
n        Next track
N        Previous track
=        Volume up
-        Volume down
s        Toggle shuffle
h        Seek backward 5s
l        Seek forward 5s
H        Seek backward 30s
L        Seek forward 30s
?        Show this help
q / Esc  Close player
]], vim.log.levels.INFO)
end

function M.close()
	if M.timer then
		M.timer:stop()
		M.timer:close()
		M.timer = nil
	end

	-- Clear resize handler
	if M.resize_group then
		vim.api.nvim_del_augroup_by_id(M.resize_group)
		M.resize_group = nil
	end

	-- Clear all artwork when closing UI
	artwork.clear_all()
	queue_artwork.clear()

	-- Clear queue cache
	M.last_queue = nil
	M.last_track_id = nil

	-- Clear autocmds for this buffer
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		vim.api.nvim_clear_autocmds({ buffer = M.buf })
	end

	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, true)
		M.win = nil
	end
end

-- Action wrappers that provide immediate visual feedback before calling backend functions
-- This makes the UI feel much more responsive

function M.action_play_pause()
	-- Guard against rapid successive calls (debounce 200ms)
	local now = vim.loop.hrtime() / 1000000 -- Convert to milliseconds
	local time_since_last = now - M.last_play_pause_time

	if time_since_last < 200 then
		return
	end
	M.last_play_pause_time = now

	local backend = get_backend()
	if not backend then
		return
	end

	if not M.last_state or M.last_state.playing == nil then
		backend.play_pause()
		render_ui()
		return
	end

	-- Save original state for rollback on error
	local original_playing = M.last_state.playing

	-- Execute the backend action FIRST (before optimistic update)
	-- This ensures the backend reads the correct current state
	backend.play_pause(function(success, err)
		-- Don't refresh immediately - let the periodic timer pick up the change
		-- This prevents bouncing when Spotify's state hasn't updated yet

		-- Only show error notification for real errors (not ignorable Spotify API issues)
		if not success and err then
			local err_lower = err:lower()
			local is_ignorable = err_lower:match("restriction") or err_lower:match("no_active_device")

			if not is_ignorable then
				-- Real error - rollback the optimistic update
				M.last_state.playing = original_playing
				render_with_state(M.last_state, M.last_queue)
				vim.notify("Play/pause failed: " .. err, vim.log.levels.WARN)
			end
		end
	end)

	-- Optimistically toggle the playing state for instant visual feedback
	-- Do this AFTER calling backend so it reads the original state
	M.last_state.playing = not M.last_state.playing

	-- Prevent periodic refreshes from overriding optimistic update for 1.5s
	-- This gives Spotify time to update its state on their end
	local now = vim.loop.hrtime() / 1000000
	M.optimistic_update_until = now + 1500

	render_with_state(M.last_state, M.last_queue)
end

function M.action_next_track()
	local backend = get_backend()
	if not backend then
		return
	end

	-- Clear main artwork and show loading state
	artwork.clear()
	-- NOTE: Don't clear queue_artwork - keep it cached for reuse!
	-- NOTE: Don't clear queue data - keep it visible during transition (optimistic UX)

	-- Save old track ID to detect when backend gives us the new track
	M.changing_from_track_id = M.last_track_id
	M.track_changing = true
	M.last_track_id = nil

	-- Show loading placeholder with current queue still visible
	if M.last_state then
		local loading_state = vim.tbl_deep_extend("force", M.last_state, {
			track_name = "Loading...",
			artist = "",
			album = "",
			-- Clear artwork fields to prevent displaying cached artwork during loading
			artwork_count = 0,
			artwork_url = nil,
		})
		render_with_state(loading_state, M.last_queue)
	end

	-- Execute the actual action
	backend.next_track()

	-- Trigger immediate refresh to get new track info
	render_ui()
end

function M.action_previous_track()
	local backend = get_backend()
	if not backend then
		return
	end

	-- Clear main artwork and show loading state
	artwork.clear()
	-- NOTE: Don't clear queue_artwork - keep it cached for reuse!
	-- NOTE: Don't clear queue data - keep it visible during transition (optimistic UX)

	-- Save old track ID to detect when backend gives us the new track
	M.changing_from_track_id = M.last_track_id
	M.track_changing = true
	M.last_track_id = nil

	-- Show loading placeholder with current queue still visible
	if M.last_state then
		local loading_state = vim.tbl_deep_extend("force", M.last_state, {
			track_name = "Loading...",
			artist = "",
			album = "",
			-- Clear artwork fields to prevent displaying cached artwork during loading
			artwork_count = 0,
			artwork_url = nil,
		})
		render_with_state(loading_state, M.last_queue)
	end

	-- Execute the actual action
	backend.previous_track()

	-- Trigger immediate refresh to get new track info
	render_ui()
end

function M.action_increase_volume()
	-- Guard against rapid successive calls (debounce 100ms)
	local now = vim.loop.hrtime() / 1000000
	if now - M.last_volume_time < 100 then
		return
	end
	M.last_volume_time = now

	local backend = get_backend()
	if not backend then
		return
	end

	if not M.last_state or not M.last_state.volume then
		backend.increase_volume()
		render_ui()
		return
	end

	-- Optimistically update volume for instant visual feedback
	M.last_state.volume = math.min(100, M.last_state.volume + 10)

	-- Prevent periodic refreshes from overriding optimistic update for 1.5s
	local now = vim.loop.hrtime() / 1000000
	M.optimistic_update_until = now + 1500

	render_with_state(M.last_state, M.last_queue)

	-- Debounce backend call (300ms delay, batches rapid presses)
	-- This saves API calls while keeping UI instant
	debouncer.schedule("volume", function()
		local final_volume = M.last_state.volume
		backend.set_volume(final_volume, function(success, err)
			if not success then
				vim.notify("Volume change failed: " .. (err or "unknown error"), vim.log.levels.WARN)
			end
			-- Refresh state after backend call completes
			render_ui()
		end)
	end)
end

function M.action_decrease_volume()
	-- Guard against rapid successive calls (debounce 100ms)
	local now = vim.loop.hrtime() / 1000000
	if now - M.last_volume_time < 100 then
		return
	end
	M.last_volume_time = now

	local backend = get_backend()
	if not backend then
		return
	end

	if not M.last_state or not M.last_state.volume then
		backend.decrease_volume()
		render_ui()
		return
	end

	-- Optimistically update volume for instant visual feedback
	M.last_state.volume = math.max(0, M.last_state.volume - 10)

	-- Prevent periodic refreshes from overriding optimistic update for 1.5s
	local now = vim.loop.hrtime() / 1000000
	M.optimistic_update_until = now + 1500

	render_with_state(M.last_state, M.last_queue)

	-- Debounce backend call (same timer as increase - both adjust final volume)
	debouncer.schedule("volume", function()
		local final_volume = M.last_state.volume
		backend.set_volume(final_volume, function(success, err)
			if not success then
				vim.notify("Volume change failed: " .. (err or "unknown error"), vim.log.levels.WARN)
			end
			-- Refresh state after backend call completes
			render_ui()
		end)
	end)
end

function M.action_toggle_shuffle()
	local backend = get_backend()
	if not backend then
		return
	end

	-- Clear queue cache since shuffle state affects queue display
	M.last_queue = nil

	-- No visual feedback for shuffle in current UI, but still trigger immediate refresh
	backend.toggle_shuffle()
	render_ui()
end

function M.action_seek_forward(seconds)
	local backend = get_backend()
	if not backend then
		return
	end

	if not M.last_state or not M.last_state.position or not M.last_state.duration then
		-- backend.seek expects milliseconds, convert seconds
		if M.last_state and M.last_state.position then
			backend.seek(math.floor((M.last_state.position + seconds) * 1000))
		end
		render_ui()
		return
	end

	-- Optimistically update position for instant visual feedback
	local new_position = math.min(M.last_state.duration, M.last_state.position + seconds)
	M.last_state.position = new_position
	render_with_state(M.last_state, M.last_queue)

	-- Debounce backend seek (allows rapid seeking without API spam)
	debouncer.schedule("seek", function()
		local final_position = M.last_state.position
		backend.seek(math.floor(final_position * 1000), function(success, err)
			if not success then
				vim.notify("Seek failed: " .. (err or "unknown error"), vim.log.levels.WARN)
			end
			-- Refresh state after backend call completes
			render_ui()
		end)
	end)
end

function M.action_seek_backward(seconds)
	local backend = get_backend()
	if not backend then
		return
	end

	if not M.last_state or not M.last_state.position then
		if M.last_state and M.last_state.position then
			backend.seek(math.floor(math.max(0, M.last_state.position - seconds) * 1000))
		end
		render_ui()
		return
	end

	-- Optimistically update position for instant visual feedback
	local new_position = math.max(0, M.last_state.position - seconds)
	M.last_state.position = new_position
	render_with_state(M.last_state, M.last_queue)

	-- Debounce backend seek (same timer as forward - both adjust final position)
	debouncer.schedule("seek", function()
		local final_position = M.last_state.position
		backend.seek(math.floor(final_position * 1000), function(success, err)
			if not success then
				vim.notify("Seek failed: " .. (err or "unknown error"), vim.log.levels.WARN)
			end
			-- Refresh state after backend call completes
			render_ui()
		end)
	end)
end

return M
