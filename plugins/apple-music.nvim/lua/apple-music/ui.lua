local player = require("apple-music.player")
local config = require("apple-music.config")
local artwork = require("apple-music.artwork")

local M = {}

M.buf = nil
M.win = nil
M.timer = nil
M.last_state = {} -- Cache state for volume controls

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

local function render_ui()
	if not M.buf or not vim.api.nvim_buf_is_valid(M.buf) then
		return
	end

	-- Async call - doesn't block the UI!
	player.get_state_async(function(state)
		-- Cache state for volume controls
		M.last_state = state

		-- Check if window still exists (user might have closed it)
		if not M.win or not vim.api.nvim_win_is_valid(M.win) then
			return
		end

		local lines = {}

		-- Reserve space at the TOP for artwork (if enabled and available)
		if state.artwork_count and state.artwork_count > 0 and config.options.artwork.enabled then
			for i = 1, 21 do -- 22 total lines for artwork area
				table.insert(lines, "")
			end
		end

		if state.player_state == "stopped" or not state.track_name then
			table.insert(lines, "")
			table.insert(lines, "  Apple Music")
			table.insert(lines, "")
			table.insert(lines, "  No track playing")
			table.insert(lines, "")
		else
			local player_icon = state.player_state == "playing" and "▶" or "⏸"

			-- Track name
			table.insert(lines, "")
			table.insert(lines, string.format("  %s  %s", player_icon, state.track_name or "Unknown"))

			-- Artist
			local artist_display = state.artist or "Unknown"
			if state.album_artist and state.album_artist ~= state.artist then
				artist_display = string.format("%s (Album: %s)", state.artist, state.album_artist)
			end
			table.insert(lines, string.format("  %s", artist_display))

			-- Album
			table.insert(lines, string.format("  %s", state.album or "Unknown Album"))

			-- Metadata line (genre, year, track/disc numbers)
			local metadata = format_metadata_line(state)
			if metadata ~= "" then
				table.insert(lines, string.format("  %s", metadata))
			end

			table.insert(lines, "")

			-- Progress bar
			local progress_width = config.options.window.width - 4
			local progress_bar = format_progress_bar(state.position, state.duration, progress_width)
			table.insert(lines, "  " .. progress_bar)
			table.insert(lines, string.format("  %s / %s", format_time(state.position), format_time(state.duration)))

			-- Stats line (favorite, play count, bit rate)
			local stats = format_stats_line(state)
			if stats ~= "" then
				table.insert(lines, string.format("  %s", stats))
			end

			table.insert(lines, "")

			-- Volume
			if state.volume then
				local volume_width = 20
				local volume_filled = math.floor((state.volume / 100) * volume_width)
				local volume_bar = string.rep("━", volume_filled) .. string.rep("─", volume_width - volume_filled)
				table.insert(lines, string.format("  Volume: %s %d%%", volume_bar, state.volume))
			end

			table.insert(lines, "")
		end

		-- IMPORTANT: Clear artwork cache before nvim_buf_set_lines
		-- nvim_buf_set_lines(0, -1) destroys all extmarks, so we need to force recreation
		local kitty = require('apple-music.kitty')
		kitty.last_display = {}

		vim.api.nvim_buf_set_option(M.buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
		vim.api.nvim_buf_set_option(M.buf, "modifiable", false)

		-- Display artwork if enabled and available (at the TOP)
		if config.options.artwork.enabled then
			if state.artwork_count and state.artwork_count > 0 then
				local current_track_id = (state.track_name or "") .. "::" .. (state.album or "")
				-- Display artwork at row 2, col 1 (0-indexed column after conversion)
				artwork.display(M.buf, 2, 1, current_track_id)
			end
			-- Note: Don't clear artwork here when artwork_count is 0!
			-- That can happen during brief player state queries.
			-- Let artwork.lua manage its own state. Only clear when window closes.
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

	vim.api.nvim_buf_set_keymap(M.buf, "n", "q", ':lua require("apple-music.ui").close()<CR>', { silent = true })
	vim.api.nvim_buf_set_keymap(M.buf, "n", "<Esc>", ':lua require("apple-music.ui").close()<CR>', { silent = true })
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"p",
		':lua require("apple-music.player").play_pause()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"n",
		':lua require("apple-music.player").next_track()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"N",
		':lua require("apple-music.player").previous_track()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"=",
		':lua require("apple-music.player").increase_volume()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"-",
		':lua require("apple-music.player").decrease_volume()<CR>',
		{ silent = true }
	)
	vim.api.nvim_buf_set_keymap(
		M.buf,
		"n",
		"s",
		':lua require("apple-music.player").toggle_shuffle()<CR>',
		{ silent = true }
	)

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

	-- Clear artwork when closing
	artwork.clear()

	-- Clear autocmds for this buffer
	if M.buf and vim.api.nvim_buf_is_valid(M.buf) then
		vim.api.nvim_clear_autocmds({ buffer = M.buf })
	end

	if M.win and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, true)
		M.win = nil
	end
end

return M
