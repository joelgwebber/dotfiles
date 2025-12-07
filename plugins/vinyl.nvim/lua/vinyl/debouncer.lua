-- Action debouncer - prevents redundant API calls during rapid user input
-- Preserves immediate optimistic UI updates while batching backend calls

local M = {}

-- Pending timers by action type
-- Structure: { [action_key] = { timer, callback } }
M.pending = {}

-- Default debounce delay in milliseconds
M.default_delay = 300

-- Schedule a debounced action
-- action_key: unique identifier for the action type (e.g., "volume", "seek")
-- callback: function to execute after delay
-- delay: optional custom delay in ms (defaults to 300ms)
function M.schedule(action_key, callback, delay)
	delay = delay or M.default_delay

	-- Cancel any pending action of the same type
	if M.pending[action_key] then
		local pending = M.pending[action_key]
		if pending.timer then
			pending.timer:stop()
			pending.timer:close()
		end
	end

	-- Schedule new action
	local timer = vim.loop.new_timer()
	timer:start(
		delay,
		0, -- Non-repeating
		vim.schedule_wrap(function()
			-- Execute callback
			callback()

			-- Clean up
			if M.pending[action_key] then
				M.pending[action_key].timer:close()
				M.pending[action_key] = nil
			end
		end)
	)

	-- Store timer
	M.pending[action_key] = {
		timer = timer,
		callback = callback,
	}
end

-- Cancel a pending action
function M.cancel(action_key)
	if M.pending[action_key] then
		local pending = M.pending[action_key]
		if pending.timer then
			pending.timer:stop()
			pending.timer:close()
		end
		M.pending[action_key] = nil
	end
end

-- Cancel all pending actions
function M.cancel_all()
	for key, pending in pairs(M.pending) do
		if pending.timer then
			pending.timer:stop()
			pending.timer:close()
		end
	end
	M.pending = {}
end

-- Check if an action is pending
function M.is_pending(action_key)
	return M.pending[action_key] ~= nil
end

return M
