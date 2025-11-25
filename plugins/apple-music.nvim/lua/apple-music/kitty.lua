-- Direct Kitty Graphics Protocol implementation
-- Spec: https://sw.kovidgoyal.net/kitty/graphics-protocol/

local M = {}

-- Unicode placeholder constants for virtual placeholder mode (matching snacks.nvim)
-- This allows images to move with buffer content instead of absolute positioning
local PLACEHOLDER = vim.fn.nr2char(0x10EEEE)

-- Diacritics from snacks.nvim (full list - supports images up to 300+ cells)
-- stylua: ignore
local diacritics_hex = vim.split(
	"0305,030D,030E,0310,0312,033D,033E,033F,0346,034A,034B,034C,0350,0351,0352,0357,035B,0363,0364,0365,0366,0367,0368,0369,036A,036B,036C,036D,036E,036F,0483,0484,0485,0486,0487,0592,0593,0594,0595,0597,0598,0599,059C,059D,059E,059F,05A0,05A1,05A8,05A9,05AB,05AC,05AF,05C4,0610,0611,0612,0613,0614,0615,0616,0617,0657,0658,0659,065A,065B,065D,065E,06D6,06D7,06D8,06D9,06DA,06DB,06DC,06DF,06E0,06E1,06E2,06E4,06E7,06E8,06EB,06EC,0730,0732,0733,0735,0736,073A,073D,073F,0740,0741,0743,0745,0747,0749,074A,07EB,07EC,07ED,07EE,07EF,07F0,07F1,07F3,0816,0817,0818,0819,081B,081C,081D,081E,081F,0820,0821,0822,0823,0825,0826,0827,0829,082A,082B,082C,082D,0951,0953,0954,0F82,0F83,0F86,0F87,135D,135E,135F,17DD,193A,1A17,1A75,1A76,1A77,1A78,1A79,1A7A,1A7B,1A7C,1B6B,1B6D,1B6E,1B6F,1B70,1B71,1B72,1B73,1CD0,1CD1,1CD2,1CDA,1CDB,1CE0,1DC0,1DC1,1DC3,1DC4,1DC5,1DC6,1DC7,1DC8,1DC9,1DCB,1DCC,1DD1,1DD2,1DD3,1DD4,1DD5,1DD6,1DD7,1DD8,1DD9,1DDA,1DDB,1DDC,1DDD,1DDE,1DDF,1DE0,1DE1,1DE2,1DE3,1DE4,1DE5,1DE6,1DFE,20D0,20D1,20D4,20D5,20D6,20D7,20DB,20DC,20E1,20E7,20E9,20F0,2CEF,2CF0,2CF1,2DE0,2DE1,2DE2,2DE3,2DE4,2DE5,2DE6,2DE7,2DE8,2DE9,2DEA,2DEB,2DEC,2DED,2DEE,2DEF,2DF0,2DF1,2DF2,2DF3,2DF4,2DF5,2DF6,2DF7,2DF8,2DF9,2DFA,2DFB,2DFC,2DFD,2DFE,2DFF,A66F,A67C,A67D,A6F0,A6F1,A8E0,A8E1,A8E2,A8E3,A8E4,A8E5,A8E6,A8E7,A8E8,A8E9,A8EA,A8EB,A8EC,A8ED,A8EE,A8EF,A8F0,A8F1,AAB0,AAB2,AAB3,AAB7,AAB8,AABE,AABF,AAC1,FE20,FE21,FE22,FE23,FE24,FE25,FE26,10A0F,10A38,1D185,1D186,1D187,1D188,1D189,1D1AA,1D1AB,1D1AC,1D1AD,1D242,1D243,1D244",
	","
)

-- Convert hex to characters (lazy loaded like snacks.nvim)
local diacritics = {}
setmetatable(diacritics, {
	__index = function(_, k)
		diacritics[k] = vim.fn.nr2char(tonumber(diacritics_hex[k], 16))
		return diacritics[k]
	end,
})

-- Namespace for extmarks
local NS = vim.api.nvim_create_namespace("apple-music-artwork")

-- Track extmarks for cleanup
M.current_extmarks = {}

-- Track last display parameters to avoid unnecessary redraws
-- Now per-image per-buffer: M.last_display[buf][image_id] = display_key
M.last_display = {}

-- Counter for unique placement IDs
M.placement_counter = 0

-- Track current placement ID per image per buffer for cleanup
-- Structure: M.current_placements[buf][image_id] = placement_id
M.current_placements = {}

-- Debug logging (write to file to avoid tty corruption)
-- Set to true to enable debug logging to /tmp/apple-music-debug.log
local DEBUG = false
local function debug_log(...)
	if not DEBUG then
		return
	end
	local log = io.open("/tmp/apple-music-debug.log", "a")
	if log then
		-- Convert all args to strings (handles booleans, numbers, etc)
		local args = { ... }
		for i, v in ipairs(args) do
			args[i] = tostring(v)
		end
		log:write(os.date("[%H:%M:%S] ") .. table.concat(args, " ") .. "\n")
		log:close()
	end
end

-- Write to terminal using nvim_ui_send (like snacks.nvim does)
-- This sends data directly to the UI without being captured by Neovim
local function write(data)
	if data == "" then
		return
	end
	if vim.api.nvim_ui_send then
		vim.api.nvim_ui_send(data)
	else
		-- Fallback to io.stdout for older Neovim versions
		io.stdout:write(data)
	end
end

-- Send a Kitty graphics protocol command
local function send_command(control, payload)
	-- Don't print during transmission - it corrupts stdout!
	local escape
	if payload then
		escape = string.format("\x1b_G%s;%s\x1b\\", control, payload)
		debug_log("[SEND_CMD] Control:", control, "Payload size:", #payload)
	else
		escape = string.format("\x1b_G%s\x1b\\", control)
		debug_log("[SEND_CMD] Control:", control, "No payload")
	end

	-- Log the exact escape sequence length
	debug_log("[SEND_CMD] Total escape size:", #escape)

	local ok, err = pcall(write, escape)
	if not ok then
		debug_log("[SEND_CMD] ERROR:", err)
	end
end

-- Base64 encode using Neovim's built-in function
local function base64_encode(data)
	-- Use vim.base64.encode if available (Neovim 0.10+), otherwise use vim.fn.system
	if vim.base64 and vim.base64.encode then
		return vim.base64.encode(data)
	else
		-- macOS base64 wraps lines at 76 chars by default - disable with -b 0
		-- Linux uses -w 0 instead, but -b works on macOS
		return vim.fn.system("base64 -b 0", data):gsub("\n", ""):gsub("\r", "")
	end
end

-- Read file contents as binary
local function read_file(path)
	local fd = vim.loop.fs_open(path, "r", 438) -- 0666 in octal
	if not fd then
		return nil, "Failed to open file"
	end

	local stat = vim.loop.fs_fstat(fd)
	if not stat then
		vim.loop.fs_close(fd)
		return nil, "Failed to stat file"
	end

	local data = vim.loop.fs_read(fd, stat.size, 0)
	vim.loop.fs_close(fd)

	return data
end

-- Transmit an image to Kitty and get back an image object
-- Returns: { id, placement_id, path }
function M.load_image(path, opts)
	opts = opts or {}
	local image_id = opts.id or math.random(1000000)

	debug_log("=== LOAD_IMAGE ===")
	debug_log("Path:", path)
	debug_log("Image ID:", image_id)

	-- Read the image file
	local data, err = read_file(path)
	if not data then
		debug_log("ERROR: Failed to read file:", err)
		return nil, err
	end
	debug_log("File size:", #data, "bytes")

	-- Encode to base64
	local ok, encoded = pcall(base64_encode, data)
	if not ok then
		debug_log("ERROR: Failed to encode:", encoded)
		return nil, encoded
	end
	debug_log("Base64 size:", #encoded, "bytes")

	-- Chunk into 4096-byte pieces for transmission
	-- IMPORTANT: All chunks except the last must be a multiple of 4 (base64 requirement)
	local chunk_size = 4096
	local chunks = {}
	for i = 1, #encoded, chunk_size do
		local chunk_end = math.min(i + chunk_size - 1, #encoded)
		local chunk = encoded:sub(i, chunk_end)
		table.insert(chunks, chunk)
	end
	debug_log("Total chunks:", #chunks)

	-- Use file-based transmission instead of direct transmission
	-- This is more reliable than chunked base64 transmission
	-- t=f: file transmission (Kitty reads directly from file)
	-- f=100: PNG format
	-- q=1: show errors
	local control = string.format("a=t,t=f,f=100,i=%d,q=1", image_id)

	-- Base64 encode the file path
	local path_encoded = base64_encode(path)

	debug_log("Using file transmission for:", path)
	debug_log("Control:", control)
	send_command(control, path_encoded)

	-- Give Kitty time to load from file
	vim.loop.sleep(100)

	debug_log("Image loaded successfully, ID:", image_id)

	-- Generate unique placement ID
	M.placement_counter = M.placement_counter + 1
	local placement_id = M.placement_counter

	return {
		id = image_id,
		placement_id = placement_id,
		path = path,
	}
end

-- Display/reposition an image at specific row/col
-- Uses virtual text extmarks so image automatically tracks with buffer
-- buf_row, buf_col are buffer-relative coordinates (1-indexed)
-- buf is the buffer to attach extmarks to
function M.display_image(image, buf_row, buf_col, width, height, buf)
	local w = width or 37
	local h = height or 18

	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		debug_log("ERROR: Invalid buffer for display_image")
		return
	end

	-- Initialize tracking structures for this buffer if needed
	if not M.last_display[buf] then
		M.last_display[buf] = {}
	end
	if not M.current_placements[buf] then
		M.current_placements[buf] = {}
	end
	if not M.current_extmarks[buf] then
		M.current_extmarks[buf] = {}
	end

	-- Check if we've already displayed this exact same image at this position
	local display_key = string.format("%d:%d:%d:%d:%d", image.id, buf_row, buf_col, w, h)
	if M.last_display[buf][image.id] == display_key then
		debug_log("[SKIP] Already displayed:", display_key)
		return
	end
	M.last_display[buf][image.id] = display_key

	-- Generate a NEW placement ID for each unique size/position combo
	-- This tells Kitty to create a new scaled placement of the same image
	M.placement_counter = M.placement_counter + 1
	local placement_id = M.placement_counter

	debug_log("=== DISPLAY_IMAGE (Virtual Text Extmarks) ===")
	debug_log("Image ID:", image.id, "Placement:", placement_id)
	debug_log("Buffer position: row", buf_row, "col", buf_col)
	debug_log("Size:", w, "x", h, "cells")

	-- Delete old placement for THIS IMAGE if it exists (by placement ID, not image ID)
	if M.current_placements[buf][image.id] then
		local old_placement_id = M.current_placements[buf][image.id]
		debug_log("[DELETE] Deleting old placement for image", image.id, ":", old_placement_id)
		-- a=d: delete, d=i: by ID, i=image_id, p=placement_id
		local control = string.format("a=d,d=i,i=%d,p=%d", image.id, old_placement_id)
		send_command(control)
	end

	-- Clear any existing extmarks for this image in this buffer
	local extmark_key = string.format("%d:%d", buf, image.id)
	if M.current_extmarks[extmark_key] then
		for _, mark_id in ipairs(M.current_extmarks[extmark_key]) do
			pcall(vim.api.nvim_buf_del_extmark, buf, NS, mark_id)
		end
	end
	M.current_extmarks[extmark_key] = {}

	-- Track this placement for future cleanup
	M.current_placements[buf][image.id] = placement_id

	-- Create a UNIQUE highlight group per image (using image ID in the name)
	-- This is how Kitty associates placeholders with images
	-- Each image needs its own highlight group so the fg (image ID) doesn't get overwritten
	local hl_name = string.format("AppleMusicImage%d", image.id)
	vim.api.nvim_set_hl(0, hl_name, {
		fg = image.id, -- CRITICAL: Just the number, not a hex color!
		sp = placement_id, -- Placement ID (matching snacks.nvim)
		bg = "none",
		nocombine = true, -- Don't combine with other highlights
	})
	debug_log("[HIGHLIGHT] Set", hl_name, "with fg =", image.id, "sp =", placement_id)

	-- Create extmarks FIRST, THEN send Kitty display command (timing matters!)
	vim.schedule(function()
		local ok, err = pcall(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				debug_log("[EXTMARK] Buffer no longer valid")
				return
			end

			-- Check how many lines exist in the buffer
			local line_count = vim.api.nvim_buf_line_count(buf)
			debug_log("[EXTMARK] Buffer has", line_count, "lines, need rows", buf_row, "to", buf_row + h - 1)

			-- Debug: Check buffer options that might affect virtual text
			local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
			local modifiable = vim.api.nvim_buf_get_option(buf, "modifiable")
			debug_log("[EXTMARK] Buffer options: buftype=", buftype, "modifiable=", modifiable)

			-- Debug: Get actual line content at target rows
			local lines = vim.api.nvim_buf_get_lines(buf, 0, 3, false)
			debug_log("[EXTMARK] First 3 lines:", vim.inspect(lines))

			-- Debug: Check if there are any windows showing this buffer
			local wins = vim.fn.win_findbuf(buf)
			debug_log("[EXTMARK] Windows showing buffer:", vim.inspect(wins))
			if #wins > 0 then
				local win = wins[1]
				local conceallevel = vim.api.nvim_win_get_option(win, "conceallevel")
				local concealcursor = vim.api.nvim_win_get_option(win, "concealcursor")
				debug_log("[EXTMARK] Window options: conceallevel=", conceallevel, "concealcursor=", concealcursor)
			end

			-- Create extmarks with virtual text containing placeholder characters
			-- One extmark per row, each with a full line of placeholders
			debug_log("[EXTMARK] Starting to create", h, "extmarks")

			for row = 0, h - 1 do
				-- Build placeholder string for this entire row
				local placeholder_line = ""
				for col = 0, w - 1 do
					-- Use 1-indexed for Lua (matching snacks.nvim)
					local row_diacritic = diacritics[row + 1]
					local col_diacritic = diacritics[col + 1]
					placeholder_line = placeholder_line .. PLACEHOLDER .. row_diacritic .. col_diacritic
				end

				-- Create extmark at column 0 (always safe)
				-- Note: buf_row is 1-indexed, but nvim_buf_set_extmark uses 0-indexed rows
				local target_row = buf_row + row - 1

				-- Debug: show first few bytes of placeholder text on first row
				if row == 0 then
					local preview = placeholder_line:sub(1, 30)
					debug_log("[EXTMARK] First placeholder preview (30 bytes):", vim.inspect(preview))
				end

				debug_log(
					"[EXTMARK] Creating extmark at row",
					target_row,
					"virt_text length:",
					#placeholder_line,
					"win_col:",
					buf_col - 1
				)

				-- Use overlay with virt_text_win_col (matching snacks.nvim exactly)
				local ok, result = pcall(vim.api.nvim_buf_set_extmark, buf, NS, target_row, 0, {
					virt_text = { { placeholder_line, hl_name } }, -- Use image-specific highlight
					virt_text_pos = "overlay", -- Overlay mode
					virt_text_hide = false, -- Don't hide (snacks uses false)
					virt_text_win_col = buf_col - 1, -- Position at window column (0-indexed)
					-- DO NOT set hl_mode! Must be nil for Kitty to detect fg color
				})

				if ok then
					table.insert(M.current_extmarks[extmark_key], result)
					debug_log("[EXTMARK] Created extmark", result, "at row", target_row)
				else
					debug_log("[EXTMARK] ERROR creating extmark:", result)
				end
			end

			debug_log(
				"Created",
				#M.current_extmarks[buf],
				"extmarks with virtual text placeholders, highlight:",
				hl_name
			)

			-- NOW send Kitty display command AFTER extmarks are created and rendered
			-- U=1: Use unicode placeholders (positions with virtual text)
			-- c,r: Specify the display rectangle size (image scales to fit this)
			-- C=1: Don't move cursor
			-- q=1: Suppress OK responses, show errors
			local control = string.format("a=p,i=%d,p=%d,c=%d,r=%d,U=1,C=1,q=1", image.id, placement_id, w, h)
			debug_log("[KITTY] Sending display command:", control)
			send_command(control)
		end) -- end of pcall

		if not ok then
			debug_log("[EXTMARK] ERROR in scheduled callback:", err)
		end
	end)
end

-- Delete a specific image by ID and clear its extmarks
function M.delete_image(image, buf)
	-- Delete the image from Kitty (deletes all placements of this image)
	local control = string.format("a=d,d=i,i=%d", image.id)
	debug_log("=== DELETE_IMAGE ===")
	debug_log("Deleting image ID:", image.id)
	send_command(control)

	-- Clear extmarks if buffer is provided
	if buf and vim.api.nvim_buf_is_valid(buf) and M.current_extmarks[buf] then
		for _, mark_id in ipairs(M.current_extmarks[buf]) do
			pcall(vim.api.nvim_buf_del_extmark, buf, NS, mark_id)
		end
		M.current_extmarks[buf] = nil
		M.last_display[buf] = nil
		M.current_placements[buf] = nil
		debug_log("Cleared extmarks for buffer")
	end
end

-- Delete all images (nuclear option)
function M.delete_all_images()
	-- a=d: delete
	-- d=a: delete all
	-- q=2: suppress responses
	debug_log("=== DELETE_ALL_IMAGES ===")
	send_command("a=d,d=a,q=2")

	-- Clear all extmarks
	for buf, mark_ids in pairs(M.current_extmarks) do
		if vim.api.nvim_buf_is_valid(buf) then
			for _, mark_id in ipairs(mark_ids) do
				pcall(vim.api.nvim_buf_del_extmark, buf, NS, mark_id)
			end
		end
	end
	M.current_extmarks = {}
	M.last_display = {}
	M.current_placements = {}
	debug_log("Cleared all extmarks and caches")
end

return M
