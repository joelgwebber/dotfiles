-- Direct Kitty Graphics Protocol implementation
-- Spec: https://sw.kovidgoyal.net/kitty/graphics-protocol/

local M = {}

-- Debug logging (write to file to avoid tty corruption)
local DEBUG = true
local function debug_log(...)
  if not DEBUG then return end
  local log = io.open('/tmp/apple-music-debug.log', 'a')
  if log then
    log:write(os.date('[%H:%M:%S] ') .. table.concat({...}, ' ') .. '\n')
    log:close()
  end
end

-- Create a proper TTY handle using Neovim's libuv bindings
-- This is how image.nvim does it - more reliable than /dev/tty
local stdout = vim.loop.new_tty(1, false)
if not stdout then
  debug_log('ERROR: Failed to create stdout TTY handle')
  error('Failed to open stdout')
end

-- Write to terminal stdout
local function write(data)
  if data == "" then return end
  stdout:write(data)
end

-- Send a Kitty graphics protocol command
local function send_command(control, payload)
  -- Don't print during transmission - it corrupts stdout!
  local escape
  if payload then
    escape = string.format('\x1b_G%s;%s\x1b\\', control, payload)
  else
    escape = string.format('\x1b_G%s\x1b\\', control)
  end
  pcall(write, escape)
end

-- Base64 encode using Neovim's built-in function
local function base64_encode(data)
  -- Use vim.base64.encode if available (Neovim 0.10+), otherwise use vim.fn.system
  if vim.base64 and vim.base64.encode then
    return vim.base64.encode(data)
  else
    -- macOS base64 wraps lines at 76 chars by default - disable with -b 0
    -- Linux uses -w 0 instead, but -b works on macOS
    return vim.fn.system('base64 -b 0', data):gsub('\n', ''):gsub('\r', '')
  end
end

-- Read file contents as binary
local function read_file(path)
  local fd = vim.loop.fs_open(path, 'r', 438) -- 0666 in octal
  if not fd then
    return nil, 'Failed to open file'
  end

  local stat = vim.loop.fs_fstat(fd)
  if not stat then
    vim.loop.fs_close(fd)
    return nil, 'Failed to stat file'
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

  debug_log('=== LOAD_IMAGE ===')
  debug_log('Path:', path)
  debug_log('Image ID:', image_id)

  -- Read the image file
  local data, err = read_file(path)
  if not data then
    debug_log('ERROR: Failed to read file:', err)
    return nil, err
  end
  debug_log('File size:', #data, 'bytes')

  -- Encode to base64
  local ok, encoded = pcall(base64_encode, data)
  if not ok then
    debug_log('ERROR: Failed to encode:', encoded)
    return nil, encoded
  end
  debug_log('Base64 size:', #encoded, 'bytes')

  -- Chunk into 4096-byte pieces for transmission
  -- IMPORTANT: All chunks except the last must be a multiple of 4 (base64 requirement)
  local chunk_size = 4096
  local chunks = {}
  for i = 1, #encoded, chunk_size do
    local chunk_end = math.min(i + chunk_size - 1, #encoded)
    local chunk = encoded:sub(i, chunk_end)
    table.insert(chunks, chunk)
  end
  debug_log('Total chunks:', #chunks)

  -- Send chunks with direct transmission
  -- f=32: RGBA format (we'll try auto-detect by not specifying format)
  -- t=d: direct transmission (send base64 encoded data)
  -- IMPORTANT: No output at all during transmission!

  -- Send chunks with direct transmission
  -- Following image.nvim's exact approach
  local m = #chunks > 1 and 1 or 0
  local control = string.format('a=t,t=d,f=100,i=%d,q=2,C=1,m=%d', image_id, m)

  for i, chunk in ipairs(chunks) do
    debug_log('Chunk', i, 'of', #chunks, '- Control:', control, '- Size:', #chunk)
    send_command(control, chunk)

    -- Update control string for next chunk (image.nvim does this AFTER sending)
    if i == #chunks - 1 then
      -- After second-to-last chunk, next (last) chunk gets m=0
      control = 'm=0'
    else
      -- All middle chunks get m=1
      control = 'm=1'
    end

    -- Small delay between chunks like image.nvim does
    vim.loop.sleep(1)
  end

  debug_log('Image loaded successfully, ID:', image_id)

  return {
    id = image_id,
    placement_id = 1,  -- Default placement
    path = path,
  }
end

-- Display/reposition an image at specific row/col
-- Uses Kitty's efficient replacement: same image_id + placement_id replaces without flicker
-- buf_row, buf_col are buffer-relative coordinates (1-indexed)
-- buf is optional - if provided, we'll find the window and convert to screen coordinates
function M.display_image(image, buf_row, buf_col, width, height, buf)
  local w = width or 37
  local h = height or 18

  -- Convert buffer-relative coordinates to absolute terminal coordinates
  local screen_row = buf_row
  local screen_col = buf_col

  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- Find the window displaying this buffer
    local wins = vim.fn.win_findbuf(buf)
    if #wins > 0 then
      local win = wins[1]
      -- Get window position on screen (0-indexed in nvim_win_get_position)
      local win_pos = vim.api.nvim_win_get_position(win)
      screen_row = win_pos[1] + buf_row  -- win_pos[1] is 0-indexed, buf_row is 1-indexed
      screen_col = win_pos[2] + buf_col  -- win_pos[2] is 0-indexed, buf_col is 1-indexed
      debug_log('Window position: row', win_pos[1], 'col', win_pos[2])
    end
  end

  debug_log('=== DISPLAY_IMAGE ===')
  debug_log('Image ID:', image.id, 'Placement:', image.placement_id)
  debug_log('Buffer position: row', buf_row, 'col', buf_col)
  debug_log('Screen position: row', screen_row, 'col', screen_col)
  debug_log('Size:', w, 'x', h, 'cells')

  -- Following image.nvim's approach:
  -- 1. Start synchronous update mode
  -- 2. Save cursor position
  -- 3. Move cursor to target position
  -- 4. Display image
  -- 5. Restore cursor
  -- 6. End synchronous update mode

  -- Synchronous update start
  write('\x1b[?2026h')

  -- Save cursor position and move to target (using absolute screen coordinates, 1-indexed)
  write('\x1b[s')  -- Save cursor
  write(string.format('\x1b[%d;%dH', screen_row, screen_col))  -- Move to position
  vim.loop.sleep(1)

  -- Display the image (using action=display for previously transmitted image)
  -- a=p: display/place
  -- i=image_id
  -- p=placement_id
  -- c=columns (width in cells)
  -- r=rows (height in cells)
  -- q=2: quiet mode (suppress responses)
  -- C=1: don't move cursor after displaying
  -- z=-1: z-index (display behind text)
  local control = string.format('a=p,i=%d,p=%d,c=%d,r=%d,q=2,C=1,z=-1', image.id, image.placement_id, w, h)
  debug_log('Control:', control)
  send_command(control)

  -- Restore cursor position
  write('\x1b[u')

  -- Synchronous update end
  write('\x1b[?2026l')
end

-- Delete a specific image by ID
function M.delete_image(image)
  -- a=d: delete
  -- d=i: delete by image id
  -- DEBUG: Removed q=2 to see Kitty's responses
  local control = string.format('a=d,d=i,i=%d', image.id)
  debug_log('=== DELETE_IMAGE ===')
  debug_log('Deleting image ID:', image.id)
  send_command(control)
end

-- Delete all images (nuclear option)
function M.delete_all_images()
  -- a=d: delete
  -- d=a: delete all
  -- q=2: suppress responses
  debug_log('=== DELETE_ALL_IMAGES ===')
  send_command('a=d,d=a,q=2')
end

return M
