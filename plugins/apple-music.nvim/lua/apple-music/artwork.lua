local player = require('apple-music.player')
local config = require('apple-music.config')

local M = {}

M.current_image = nil
M.current_track_id = nil  -- Track which track's artwork we're showing
M.is_loading = false  -- Prevent duplicate fetches
M.temp_file = nil  -- Track the temp file path for cleanup

-- Check if image.nvim is available
local function has_image_nvim()
  local ok, image = pcall(require, 'image')
  return ok and image ~= nil
end

-- Clear current artwork
function M.clear()
  if M.current_image then
    -- Try multiple cleanup methods to ensure image is removed
    pcall(function()
      M.current_image:clear()
    end)
    pcall(function()
      if M.current_image.delete then
        M.current_image:delete()
      end
    end)
    M.current_image = nil
  end

  -- Also try to clear by ID prefix (nuclear option to prevent ghosts)
  if has_image_nvim() then
    local ok, image_module = pcall(require, 'image')
    if ok and image_module.get_images then
      pcall(function()
        -- Clear all apple-music images
        local images = image_module.get_images()
        for _, img in ipairs(images) do
          if img.id and img.id:match('^apple%-music%-') then
            pcall(function() img:clear() end)
            pcall(function() if img.delete then img:delete() end end)
          end
        end
      end)
    end
  end

  -- Delete the old temp file to force Kitty to reload
  if M.temp_file then
    pcall(function()
      vim.fn.delete(M.temp_file)
    end)
    M.temp_file = nil
  end

  -- Force terminal to clear all Kitty graphics (nuclear option)
  -- This sends the Kitty graphics protocol command to delete all images
  vim.fn.system('printf "\\033_Ga=d\\033\\\\"')

  -- Force a redraw to ensure terminal updates
  vim.schedule(function()
    vim.cmd('redraw!')
  end)

  M.current_track_id = nil
  M.is_loading = false
end

-- Re-render the current image at a new position (without fetching)
function M.reposition(row, col)
  if not M.current_image then
    return
  end

  -- Calculate dimensions
  local max_width_chars = math.floor(config.options.artwork.max_width / 8)
  local max_height_chars = math.floor(config.options.artwork.max_height / 16)

  -- Re-render at new position
  pcall(function()
    M.current_image:render({
      x = col,
      y = row,
      width = max_width_chars,
      height = max_height_chars,
    })
  end)
end

-- Display artwork in the buffer
function M.display(buf, row, col, track_id)
  if not config.options.artwork.enabled then
    return
  end

  if not has_image_nvim() then
    return
  end

  -- If this is the same track and image exists, just reposition it
  if track_id and M.current_track_id == track_id and M.current_image then
    M.reposition(row, col)
    return
  end

  -- If already loading this track, skip
  if M.is_loading then
    return
  end

  -- Clear old image FIRST, before fetching new one
  -- This ensures the screen is empty before we render new artwork
  M.clear()

  -- Delete the temp file to force a fresh write (Kitty might cache by file path)
  pcall(function()
    vim.fn.delete('/tmp/apple-music-artwork.jpg')
  end)

  -- Mark as loading AFTER clear so clear() doesn't reset the flag
  M.is_loading = true

  -- Get artwork asynchronously
  player.get_artwork_async(function(artwork, err)
    if err or not artwork then
      -- Clear if fetch failed
      M.is_loading = false
      return
    end

    -- Create a unique file path for this track to avoid Kitty caching
    local track_hash = (track_id or 'unknown'):gsub('[^%w]', '-')
    local unique_path = string.format('/tmp/apple-music-%s.jpg', track_hash)

    -- Copy the AppleScript-created file to the unique path
    local copy_result = vim.fn.system(string.format('cp "%s" "%s"', artwork.path, unique_path))

    -- Save the temp file for cleanup
    M.temp_file = unique_path

    -- Small delay to ensure file copy completes and terminal clears
    vim.defer_fn(function()

      -- Create new image
      local ok, image_module = pcall(require, 'image')
      if not ok then
        return
      end

      -- Get the window for this buffer
      local win = vim.fn.bufwinid(buf)
      if win == -1 then
        return -- Window not found
      end

      -- Calculate dimensions in characters (approx 8px per char width, 16px per char height)
      -- For a 300px square image: ~37 chars wide, ~18 chars tall
      local max_width_chars = math.floor(config.options.artwork.max_width / 8)
      local max_height_chars = math.floor(config.options.artwork.max_height / 16)

      -- Use unique ID for each track to avoid caching issues
      local image_id = 'apple-music-' .. track_hash

      -- Try to create the image from the unique file path
      local ok2, img_or_err = pcall(image_module.from_file, unique_path, {
        id = image_id,
        window = win,
        buffer = buf,
        with_virtual_padding = false,
        inline = true,  -- Use inline mode for docked windows
        x = col,
        y = row,
        width = max_width_chars,
        height = max_height_chars,
      })

      if ok2 and img_or_err then
        -- Wait longer to ensure terminal has processed the clear command
        vim.defer_fn(function()
          vim.schedule(function()
            local ok3, err3 = pcall(function()
              img_or_err:render()
            end)
            if ok3 then
              -- Only save the image and track ID if render succeeded
              M.current_image = img_or_err
              M.current_track_id = track_id
              M.is_loading = false
              -- Force a redraw
              vim.cmd('redraw')
            else
              -- Clear on render failure
              pcall(function() img_or_err:clear() end)
              M.is_loading = false
            end
          end)
        end, 200)
      else
        M.is_loading = false
      end
    end, 100)
  end)
end

return M
