MetaFly = {}

local logger = nil

MetaFly.options = {}
MetaFly.noteBoxes = {}

function MetaFly.setup(opts)
	local config = require("MetaFly.config"):getInstance()
	config:setOptions(opts)
	logger = config:getLogger()
	local db = require("MetaFly.model.database"):getInstance()
	logger.info("MetaFly Database initialized at: " .. db:getUri())

	-- Scan note boxes asynchronously in the background so that
	-- Neovim startup is not blocked by file scanning.
	local AsyncScanner = require("MetaFly.controller.AsyncScanner")
	AsyncScanner.scanInBackground(opts)
end

return MetaFly
