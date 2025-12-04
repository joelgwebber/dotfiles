local player = require("apple-music.player")
local config = require("apple-music.config")
local artwork = require("apple-music.artwork")
local queue_artwork = require("apple-music.queue_artwork")
local hl = require("apple-music.highlights")

local M = {}

M.buf = nil
M.win = nil
M.timer = nil
M.last_state = {} -- Cache state for volume controls
M.last_queue = nil -- Cache queue data
M.last_track_id = nil -- Track ID to detect track changes
M.resize_group = nil -- Autocmd group for resize handling

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

	return "  " .. "    " .. " " .. text  -- 2ch margin + 4ch image placeholder + 1ch spacing
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
	local highlights = {}  -- Track { line, col_start, col_end, hl_group }

	-- Reserve space at the TOP for artwork (if enabled)
	-- Always reserve space to prevent text jumping when loading/changing tracks
	if config.options.artwork.enabled then
		if state.artwork_count and state.artwork_count > 0 then
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

	if state.player_state == "stopped" or not state.track_name then
		table.insert(lines, "")
		table.insert(lines, centered_line("Apple Music", win_width))
		table.insert(lines, "")
		table.insert(lines, centered_line("No track playing", win_width))
		table.insert(lines, "")
	else
		local player_icon = state.player_state == "playing" and "▶" or "⏸"

		-- Track name with player icon
		table.insert(lines, "")
		table.insert(lines, centered_line(string.format("%s  %s", player_icon, state.track_name or "Unknown"), win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Title') })

		-- Artist
		local artist_display = state.artist or "Unknown"
		if state.album_artist and state.album_artist ~= state.artist then
			artist_display = string.format("%s (Album: %s)", state.artist, state.album_artist)
		end
		table.insert(lines, centered_line(artist_display, win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Artist') })

		-- Album
		table.insert(lines, centered_line(state.album or "Unknown Album", win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Album') })

		-- Metadata line (genre, year, track/disc numbers)
		local metadata = format_metadata_line(state)
		if metadata ~= "" then
			table.insert(lines, centered_line(metadata, win_width))
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Label') })
		end

		table.insert(lines, "")

		-- Progress bar (scales with window width)
		local progress_bar = format_progress_bar(state.position, state.duration, usable_width)
		table.insert(lines, "  " .. progress_bar)

		-- Time display
		local time_display = string.format("%s / %s", format_time(state.position), format_time(state.duration))
		table.insert(lines, centered_line(time_display, win_width))
		table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Time') })

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
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Volume') })
		end

		table.insert(lines, "")
	end

	-- Queue section (upcoming tracks)
	local queue_tracks_to_render = {}  -- Track which tracks need artwork

	if queue then
		table.insert(lines, "")
		table.insert(lines, centered_line("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", win_width))
		table.insert(lines, "")

		-- Show queue position
		if queue.current_index and queue.total_tracks then
			local position_text = string.format("Queue: %d/%d", queue.current_index, queue.total_tracks)
			table.insert(lines, centered_line(position_text, win_width))
			table.insert(lines, "")
		end

		-- Check if shuffle is enabled
		if queue.shuffle_enabled then
			-- Shuffle is on - can't show queue order
			table.insert(lines, centered_line("🔀 Shuffle enabled", win_width))
			table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('Shuffle') })
			table.insert(lines, "")
		elseif queue.upcoming_tracks and #queue.upcoming_tracks > 0 then
			-- Render upcoming tracks (2 lines per track with artwork + blank line)
			for i, track in ipairs(queue.upcoming_tracks) do
				-- Save the 1-indexed line number where track name will be inserted
				-- This aligns the top of the 4x2 thumbnail with the track name
				table.insert(queue_tracks_to_render, {
					album = track.album,
					line = #lines + 1,  -- 1-indexed line number for display_image
				})

				table.insert(lines, queue_line_with_artwork(track.name, win_width))
				table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('QueueTrack') })
				table.insert(lines, queue_line_with_artwork(track.artist, win_width))
				table.insert(highlights, { line = #lines - 1, col_start = 0, col_end = -1, group = hl.get('QueueArtist') })

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
	local kitty = require('apple-music.kitty')
	kitty.last_display[M.buf] = {}  -- Clear display cache for this buffer

	vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)

	-- Apply syntax highlighting (do this before making buffer non-modifiable)
	for _, hl_info in ipairs(highlights) do
		vim.api.nvim_buf_add_highlight(
			M.buf,
			-1,  -- namespace (0 = default, -1 = no namespace)
			hl_info.group,
			hl_info.line,
			hl_info.col_start,
			hl_info.col_end
		)
	end

	vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

	-- Display artwork if enabled and available (at the TOP)
	if config.options.artwork.enabled then
		if state.artwork_count and state.artwork_count > 0 and state.album then
			-- Calculate centered column position (size already calculated above)
			local centered_col = math.floor((win_width - artwork_width_chars) / 2) + 1 -- 1-indexed

			-- Use album name for caching (more efficient than per-track)
			artwork.display(M.buf, 2, centered_col, state.album, artwork_width_chars, artwork_height_chars)
		end
		-- Note: Don't clear artwork here when artwork_count is 0!
		-- That can happen during brief player state queries.
		-- Let artwork.lua manage its own state. Only clear when window closes.

		-- Display queue artwork (4x2 images on the left, top-aligned with track names)
		if queue_tracks_to_render and #queue_tracks_to_render > 0 then
			for _, track_info in ipairs(queue_tracks_to_render) do
				if track_info.album and track_info.album ~= '' then
					-- Display 4x2 artwork at column 2, with 2ch left margin
					-- track_info.line is 1-indexed (line number in editor)
					queue_artwork.display_album_artwork(
						track_info.album,
						M.buf,
						track_info.line,  -- 1-indexed row where track name starts
						2,                -- Column (0-indexed, after 2ch margin)
						nil               -- No callback needed
					)
				end
			end
		end
	end
end

-- Fetch state from AppleScript and render
local function render_ui()
	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		return
	end

	-- Async call - doesn't block the UI!
	player.get_state_async(function(state)
		-- Cache state for volume controls and resize handling
		M.last_state = state

		-- Detect track changes to fetch queue efficiently
		local current_track_id = (state.track_name or "") .. "::" .. (state.album or "")
		local track_changed = (M.last_track_id ~= current_track_id)
		local queue_missing = (M.last_queue == nil)

		-- Fetch queue if track changed OR if queue cache is missing (e.g., after shuffle toggle)
		if track_changed or queue_missing then
			if track_changed then
				M.last_track_id = current_track_id
			end

			-- Fetch queue asynchronously
			player.get_queue_async(function(queue, err)
				if queue then
					M.last_queue = queue
					-- Re-render with new queue data
					render_with_state(state, queue)
				else
					-- No queue available, render without it
					M.last_queue = nil
					render_with_state(state, nil)
				end
			end)
		else
			-- Track hasn't changed and queue exists, use cached queue
			render_with_state(state, M.last_queue)
		end
	end)
end

function M.toggle()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		M.close()
	else
		M.open()
	end
end

function M.open()
	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_set_current_win(M.win)
		return
	end

	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		M.buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(M.buf, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(M.buf, "filetype", "apple-music")
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
	vim.api.nvim_win_set_option(M.win, "conceallevel", 0)  -- Don't conceal placeholders!
	vim.api.nvim_win_set_option(M.win, "winfixwidth", true)  -- Dock behavior - don't resize when balancing splits

	vim.api.nvim_buf_set_keymap(M.buf, "n", "q", ':lua require("apple-music.ui").close()<CR>', { silent = true })
	vim.api.nvim_buf_set_keymap(M.buf, "n", "<Esc>", ':lua require("apple-music.ui").close()<CR>', { silent = true })
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"p",
		':lua require("apple-music.ui").action_play_pause()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"n",
		':lua require("apple-music.ui").action_next_track()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"N",
		':lua require("apple-music.ui").action_previous_track()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"=",
		':lua require("apple-music.ui").action_increase_volume()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"-",
		':lua require("apple-music.ui").action_decrease_volume()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"s",
		':lua require("apple-music.ui").action_toggle_shuffle()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"h",
		':lua require("apple-music.ui").action_seek_backward(5)<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"l",
		':lua require("apple-music.ui").action_seek_forward(5)<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"H",
		':lua require("apple-music.ui").action_seek_backward(30)<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"L",
		':lua require("apple-music.ui").action_seek_forward(30)<CR>',
		{ silent = true }
	)

	-- Set up resize handler (instant visual feedback without AppleScript)
	if not M.resize_group then
		M.resize_group = vim.api.nvim_create_augroup("AppleMusicResize", { clear = true })
	end
	vim.api.nvim_create_autocmd("WinResized", {
		group = M.resize_group,
		callback = function()
			-- Only re-render if our window was resized
			if M.win and vim.api.nvim_win_is_valid(M.win) and vim.tbl_contains(vim.v.event.windows, M.win) then
				-- Re-render with cached state (no AppleScript call)
				if M.last_state and M.last_state.track_name then
					render_with_state(M.last_state, M.last_queue)
				end
			end
		end,
	})

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

-- Action wrappers that provide immediate visual feedback before calling player functions
-- This makes the UI feel much more responsive

function M.action_play_pause()
	if not M.last_state or not M.last_state.player_state then
		player.play_pause()
		render_ui()
		return
	end

	-- Optimistically toggle the player state for instant visual feedback
	if M.last_state.player_state == "playing" then
		M.last_state.player_state = "paused"
	elseif M.last_state.player_state == "paused" then
		M.last_state.player_state = "playing"
	end

	-- Re-render with optimistic state (instant!)
	render_with_state(M.last_state, M.last_queue)

	-- Execute the actual action
	player.play_pause()

	-- Trigger immediate refresh to get accurate state (reduces perceived latency to just AppleScript round-trip)
	render_ui()
end

function M.action_next_track()
	-- Clear main artwork and show loading state
	artwork.clear()
	-- NOTE: Don't clear queue_artwork - keep it cached for reuse!

	-- Clear queue data cache to force refresh
	M.last_queue = nil
	M.last_track_id = nil

	-- Show loading placeholder
	if M.last_state then
		local loading_state = vim.tbl_deep_extend("force", M.last_state, {
			track_name = "Loading...",
			artist = "",
			album = "",
			artwork_count = 0,
		})
		render_with_state(loading_state, nil)
	end

	-- Execute the actual action
	player.next_track()

	-- Trigger immediate refresh to get new track info
	render_ui()
end

function M.action_previous_track()
	-- Clear main artwork and show loading state
	artwork.clear()
	-- NOTE: Don't clear queue_artwork - keep it cached for reuse!

	-- Clear queue data cache to force refresh
	M.last_queue = nil
	M.last_track_id = nil

	-- Show loading placeholder
	if M.last_state then
		local loading_state = vim.tbl_deep_extend("force", M.last_state, {
			track_name = "Loading...",
			artist = "",
			album = "",
			artwork_count = 0,
		})
		render_with_state(loading_state, nil)
	end

	-- Execute the actual action
	player.previous_track()

	-- Trigger immediate refresh to get new track info
	render_ui()
end

function M.action_increase_volume()
	if not M.last_state or not M.last_state.volume then
		player.increase_volume()
		render_ui()
		return
	end

	-- Optimistically update volume for instant visual feedback
	M.last_state.volume = math.min(100, M.last_state.volume + 10)
	render_with_state(M.last_state, M.last_queue)

	-- Execute the actual action
	player.increase_volume()

	-- Trigger immediate refresh to get accurate volume
	render_ui()
end

function M.action_decrease_volume()
	if not M.last_state or not M.last_state.volume then
		player.decrease_volume()
		render_ui()
		return
	end

	-- Optimistically update volume for instant visual feedback
	M.last_state.volume = math.max(0, M.last_state.volume - 10)
	render_with_state(M.last_state, M.last_queue)

	-- Execute the actual action
	player.decrease_volume()

	-- Trigger immediate refresh to get accurate volume
	render_ui()
end

function M.action_toggle_shuffle()
	-- Clear queue cache since shuffle state affects queue display
	M.last_queue = nil

	-- No visual feedback for shuffle in current UI, but still trigger immediate refresh
	player.toggle_shuffle()
	render_ui()
end

function M.action_seek_forward(seconds)
	if not M.last_state or not M.last_state.position or not M.last_state.duration then
		player.seek_forward(seconds)
		render_ui()
		return
	end

	-- Optimistically update position for instant visual feedback
	M.last_state.position = math.min(M.last_state.duration, M.last_state.position + seconds)
	render_with_state(M.last_state, M.last_queue)

	-- Execute the actual action
	player.seek_forward(seconds)

	-- Trigger immediate refresh to get accurate position
	render_ui()
end

function M.action_seek_backward(seconds)
	if not M.last_state or not M.last_state.position then
		player.seek_backward(seconds)
		render_ui()
		return
	end

	-- Optimistically update position for instant visual feedback
	M.last_state.position = math.max(0, M.last_state.position - seconds)
	render_with_state(M.last_state, M.last_queue)

	-- Execute the actual action
	player.seek_backward(seconds)

	-- Trigger immediate refresh to get accurate position
	render_ui()
end

return M
