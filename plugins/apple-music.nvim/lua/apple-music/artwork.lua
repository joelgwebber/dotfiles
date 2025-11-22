local player = require('apple-music.player')
local config = require('apple-music.config')

local M = {}

M.current_image = nil
M.current_artwork_path = nil

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

  -- Also try to clear by ID
  if has_image_nvim() then
    local ok, image_module = pcall(require, 'image')
    if ok and image_module.clear then
      pcall(function()
        -- Clear all images (nuclear option to prevent ghosts)
        local images = image_module.get_images()
        for _, img in ipairs(images) do
          if img.id == 'apple-music-artwork' then
            pcall(function() img:clear() end)
            pcall(function() img:delete() end)
          end
        end
      end)
    end
  end

  M.current_artwork_path = nil
end

-- Display artwork in the buffer
function M.display(buf, row, col)
  if not config.options.artwork.enabled then
    return
  end

  if not has_image_nvim() then
    return
  end

  -- Get artwork asynchronously
  player.get_artwork_async(function(artwork, err)
    if err or not artwork then
      M.clear()
      return
    end

    -- If this is the same artwork, don't reload
    if M.current_artwork_path == artwork.path and M.current_image then
      return
    end

    -- Clear old image first
    M.clear()

    -- Small delay to let cleanup complete
    vim.defer_fn(function()
      -- Save new path
      M.current_artwork_path = artwork.path

      -- Create new image
      local ok, image_module = pcall(require, 'image')
      if not ok then
        return
      end

      -- Try to create and render the image
      local ok2, img = pcall(image_module.from_file, artwork.path, {
        id = 'apple-music-artwork',
        buffer = buf,
        with_virtual_padding = false,
        inline = false,  -- Don't use inline mode with floating windows
        x = col,
        y = row,
        max_width = config.options.artwork.max_width,
        max_height = config.options.artwork.max_height,
      })

      if ok2 and img then
        M.current_image = img
        -- Delay render slightly to avoid layout jumping
        vim.defer_fn(function()
          pcall(function()
            img:render()
          end)
        end, 50)
      end
    end, 100)
  end)
end

return M
