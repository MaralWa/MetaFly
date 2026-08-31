-- AsyncScanner: Asynchronous wrapper for note box scanning.
-- Prevents blocking Neovim during startup by deferring the scan
-- and yielding control back to the event loop between each note box.

local AsyncScanner = {}

local logger = nil

--- Build a text-based progress bar string.
--- @param current number Current progress count
--- @param total number Total expected count
--- @param width number|nil Character width of the bar (default: 30)
--- @return string Formatted progress bar, e.g. "[████░░░░] 2/5"
local function build_progress_bar(current, total, width)
	width = width or 30
	local ratio = total > 0 and (current / total) or 0
	local filled = math.floor(ratio * width)
	local bar = string.rep("█", filled) .. string.rep("░", width - filled)
	return string.format("[%s] %d/%d", bar, current, total)
end

--- Scan all configured note boxes in the background.
---
--- Uses vim.schedule() to yield control back to Neovim's event loop
--- between each note box so the editor remains responsive while scanning.
--- The existing SetUpController:scanNoteBox() method is called unchanged
--- for the actual scanning and YAML header processing.
---
--- A simple text progress bar is shown via vim.notify() to indicate
--- how many note boxes have been processed.
---
--- @param opts table Plugin options containing the noteBoxes configuration
function AsyncScanner.scanInBackground(opts)
	logger = require("MetaFly.config"):getInstance():getLogger("AsyncScanner")

	local noteBoxConfigs = opts["noteBoxes"]
	if not noteBoxConfigs or next(noteBoxConfigs) == nil then
		logger.info("No note boxes configured, skipping scan.")
		return
	end

	-- Convert the config table to an indexed list for sequential processing
	local configs = {}
	for _, cfg in pairs(noteBoxConfigs) do
		table.insert(configs, cfg)
	end

	local total = #configs
	local current = 0

	-- Create the SetUpController instance that performs the actual scanning
	local setUpController = require("MetaFly.controller.SetUpController"):new()

	vim.notify(
		"MetaFly: Starting background scan of " .. total .. " note box(es)...",
		vim.log.levels.INFO
	)
	logger.info("Starting async scan of " .. total .. " note box(es)")

	--- Process the next note box in the queue.
	--- After each note box is scanned, the function schedules itself
	--- via vim.schedule() so the event loop can handle other events
	--- (keystrokes, UI redraws, etc.) in between.
	local function processNextNoteBox()
		current = current + 1

		if current > total then
			-- All note boxes have been processed
			vim.notify("MetaFly: Scan complete ✓", vim.log.levels.INFO)
			logger.info("Background scan complete.")
			return
		end

		local config = configs[current]
		local name = config.name or "unknown"
		local progress = build_progress_bar(current, total)

		vim.notify(
			string.format("MetaFly: %s Scanning '%s'...", progress, name),
			vim.log.levels.INFO
		)
		logger.info("Scanning note box: " .. name)

		-- Use the existing scanNoteBox method without modification
		setUpController:scanNoteBox(config)

		-- Yield to the event loop before processing the next note box
		vim.schedule(processNextNoteBox)
	end

	-- Defer the first step so that setup() returns immediately
	-- and does not block Neovim startup
	vim.schedule(processNextNoteBox)
end

return AsyncScanner
