-- Lifecycle: centralized shutdown state and cleanup of timers/handles.

local M = {
	shutting_down = false,
	timers = {},
	handles = {},
}

function M.is_shutting_down()
	return M.shutting_down
end

function M.register_timer(timer)
	if timer then
		table.insert(M.timers, timer)
	end
	return timer
end

function M.register_handle(handle)
	if handle then
		table.insert(M.handles, handle)
	end
	return handle
end

local function close_handle(h)
	pcall(function()
		if h.stop then
			h:stop()
		end
	end)
	pcall(function()
		if not (h.is_closing and h:is_closing()) and h.close then
			h:close()
		end
	end)
end

function M.shutdown()
	if M.shutting_down then
		return
	end
	M.shutting_down = true

	for _, t in ipairs(M.timers) do
		close_handle(t)
	end
	M.timers = {}

	for _, h in ipairs(M.handles) do
		close_handle(h)
	end
	M.handles = {}

	pcall(function()
		local clients = vim.lsp.get_clients()
		for _, c in ipairs(clients) do
			pcall(function()
				c:stop(true)
			end)
		end
	end)
end

return M
