local config = require('apple-music.config')
local player = require('apple-music.player')
local ui = require('apple-music.ui')
local debug = require('apple-music.debug')

local M = {}

-- Debug commands
M.debug = debug

function M.setup(opts)
  config.setup(opts)
end

M.toggle_ui = ui.toggle
M.open_ui = ui.open
M.close_ui = ui.close

M.play_pause = player.play_pause
M.next_track = player.next_track
M.previous_track = player.previous_track
M.increase_volume = player.increase_volume
M.decrease_volume = player.decrease_volume
M.toggle_shuffle = player.toggle_shuffle

return M
