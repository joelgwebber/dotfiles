local player = require('apple-music.player')
local config = require('apple-music.config')
local kitty = require('apple-music.kitty')

local M = {}

M.current_image = nil
M.current_track_id = nil
M.is_loading = false
M.temp_file = nil
M.current_buf = nil

-- Clear current artwork
function M.clear()
  if M.current_image then
    kitty.delete_image(M.current_image, M.current_buf)
    M.current_image = nil
  end

  -- Delete the old temp file
  if M.temp_file then
    pcall(function()
      vim.fn.delete(M.temp_file)
    end)
    M.temp_file = nil
  end

  -- Force a redraw to ensure terminal updates
  vim.schedule(function()
    vim.cmd('redraw!')
  end)

  M.current_track_id = nil
  M.is_loading = false
end

-- Display artwork in the buffer
function M.display(buf, row, col, track_id)
  if not config.options.artwork.enabled then
    return
  end

  -- Save the buffer reference for cleanup
  M.current_buf = buf

  -- Calculate dimensions in characters (approx 8px per char width, 16px per char height)
  local max_width_chars = math.floor(config.options.artwork.max_width / 8)
  local max_height_chars = math.floor(config.options.artwork.max_height / 16)

  -- If this is the same track and image exists, just reposition it
  -- This is the key optimization: Kitty can reposition without re-transmitting!
  if track_id and M.current_track_id == track_id and M.current_image then
    kitty.display_image(M.current_image, row, col, max_width_chars, max_height_chars, buf)
    return
  end

  -- If already loading this track, skip
  if M.is_loading then
    return
  end

  -- Clear old image FIRST, before fetching new one
  M.clear()

  -- Mark as loading AFTER clear so clear() doesn't reset the flag
  M.is_loading = true

  -- Get artwork asynchronously
  player.get_artwork_async(function(artwork, err)
    if err or not artwork then
      M.is_loading = false
      return
    end

    -- Create a unique file path for this track to avoid caching
    local track_hash = (track_id or 'unknown'):gsub('[^%w]', '-')
    local unique_path = string.format('/tmp/apple-music-%s.png', track_hash)  -- Use .png extension

    -- Convert JPEG to PNG using ImageMagick (Kitty needs PNG for direct transmission)
    local convert_result = vim.fn.system(string.format('convert "%s" "%s"', artwork.path, unique_path))
    if vim.v.shell_error ~= 0 then
      M.is_loading = false
      return
    end

    -- Verify the PNG is valid before sending
    local verify_result = vim.fn.system(string.format('file "%s"', unique_path))
    if not verify_result:match('PNG image data') then
      M.is_loading = false
      return
    end

    -- Save the temp file for cleanup
    M.temp_file = unique_path

    -- Small delay to ensure file copy completes
    vim.defer_fn(function()
      -- Load the image into Kitty
      local img, load_err = kitty.load_image(unique_path, {
        id = math.random(1000000)  -- Unique ID per track
      })

      if not img then
        M.is_loading = false
        return
      end

      -- Display at the specified position
      kitty.display_image(img, row, col, max_width_chars, max_height_chars, buf)

      -- Save state
      M.current_image = img
      M.current_track_id = track_id
      M.is_loading = false

      -- Force a redraw
      vim.schedule(function()
        vim.cmd('redraw')
      end)
    end, 100)
  end)
end

return M
