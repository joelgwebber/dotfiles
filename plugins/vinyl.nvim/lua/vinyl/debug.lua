local player = require("vinyl.player")

local M = {}

function M.test_state()
	print("Testing player state...")
	player.get_state_async(function(state)
		print("=== Player State ===")
		print("player_state: " .. tostring(state.player_state))
		print("track_name: " .. tostring(state.track_name))
		print("artist: " .. tostring(state.artist))
		print("album: " .. tostring(state.album))
		print("genre: " .. tostring(state.genre))
		print("year: " .. tostring(state.year))
		print("===================")
		vim.print(state)
	end)
end

function M.test_raw_applescript()
	print("Testing raw AppleScript...")
	vim.system(
		{ "osascript", "-e", 'tell application "Music" to return player state as string' },
		{ text = true },
		function(result)
			vim.schedule(function()
				print("Exit code: " .. result.code)
				print("Stdout: " .. vim.trim(result.stdout))
				print("Stderr: " .. result.stderr)
			end)
		end
	)
end

return M
