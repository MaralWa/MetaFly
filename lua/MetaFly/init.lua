MetaFly = {}

local logger = nil

MetaFly.options = {}
MetaFly.noteBoxes = {}

local lifecycle_registered = false

local function register_lifecycle()
	if lifecycle_registered then
		return
	end
	lifecycle_registered = true
	local group = vim.api.nvim_create_augroup("MetaFlyLifecycle", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			pcall(require("MetaFly.lifecycle").shutdown)
		end,
	})
end

function MetaFly.setup(opts)
	local config = require("MetaFly.config"):getInstance()
	config:setOptions(opts)
	register_lifecycle()
	logger = config:getLogger().child("setup")
	local db = require("MetaFly.model.database"):getInstance()
	logger.info("MetaFly Database initialized at: " .. db:getUri())

	-- Scan note boxes asynchronously in the background so that
	-- Neovim startup is not blocked by file scanning.
	local AsyncScanner = require("MetaFly.controller.AsyncScanner")
	AsyncScanner.scanInBackground(opts)
end

return MetaFly
