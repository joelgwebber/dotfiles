-- Utility functions for Neovim configuration

local M = {}

-- Open a file with the system's default application
-- @param filepath string: Full path to the file to open
function M.open_with_system(filepath)
  if not filepath or filepath == '' then
    vim.notify('No file path provided', vim.log.levels.WARN)
    return
  end

  -- Detect OS and use appropriate command
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = { 'open', filepath }
  elseif vim.fn.has('unix') == 1 then
    cmd = { 'xdg-open', filepath }
  elseif vim.fn.has('win32') == 1 then
    cmd = { 'cmd', '/c', 'start', '""', filepath }
  else
    vim.notify('Unsupported OS', vim.log.levels.ERROR)
    return
  end

  vim.system(cmd, { detach = true }, function(result)
    if result.code ~= 0 then
      vim.notify('Failed to open file: ' .. (result.stderr or 'Unknown error'), vim.log.levels.ERROR)
    end
  end)
end

-- Debug function to check if a keymap exists
-- @param mode string: Mode to check ('i', 'n', etc.)
-- @param lhs string: Left-hand side of the mapping
function M.check_keymap(mode, lhs)
  local maps = vim.api.nvim_get_keymap(mode)
  for _, map in pairs(maps) do
    if map.lhs == lhs then
      return map
    end
  end

  -- Also check buffer-local maps
  local buf_maps = vim.api.nvim_buf_get_keymap(0, mode)
  for _, map in pairs(buf_maps) do
    if map.lhs == lhs then
      return map
    end
  end

  return nil
end

-- Debug function to inspect Copilot status
function M.debug_copilot()
  local copilot_ok, copilot = pcall(require, 'copilot.api')
  if not copilot_ok then
    vim.notify('Copilot not loaded', vim.log.levels.ERROR)
    return
  end

  local status = copilot.status()
  local info = {
    'Copilot Debug Info:',
    '  Status: ' .. (status.status or 'unknown'),
    '  Message: ' .. (status.message or 'none'),
  }

  -- Check if suggestion is available
  local suggestion_ok, suggestion = pcall(require, 'copilot.suggestion')
  if suggestion_ok then
    local has_suggestion = suggestion.is_visible()
    table.insert(info, '  Has visible suggestion: ' .. tostring(has_suggestion))
  end

  vim.notify(table.concat(info, '\n'), vim.log.levels.INFO)
end

-- Debug function to log keymap calls
function M.debug_log(message)
  local timestamp = os.date('%H:%M:%S')
  local log_msg = string.format('[%s] COPILOT DEBUG: %s', timestamp, message)
  vim.notify(log_msg, vim.log.levels.INFO)
end

return M