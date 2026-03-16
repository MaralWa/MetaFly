local Logger = {}

local instance = nil

Logger.config = {
	title = "MetaFly", -- Standaurdtitel für Benachrichtigungen
	level = vim.log.levels.ERROR, -- Loggerindest-Level
}

---@param opts MetaFly.config.Logger | nil
local function new()
	local self = setmetatable({}, { __index = Logger })
	local config = require("MetaFly.config"):getInstance().logger
	self.level = vim.log.levels[config.level] or vim.log.levels.ERROR
	self.logger = require("plenary.log").new({
		plugin = "my_plugin",
		level = vim.log.levels[config.level],
		use_console = "sync",
		use_file = true,
		outfile = config.logFile,
	})
	return self
end

Logger.getInstance = function()
	if not instance then
		instance = new()
	end
	return instance
end

-- Convenience Wrapper
function Logger:debug(msg)
	if self.level >= vim.log.levels.DEBUG then
		self.logger.fmt_debug("%s DEBUG: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:info(msg)
	if self.level >= vim.log.levels.INFO then
		self.logger.fmt_info("%s INFO: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:warn(msg)
	if self.level >= vim.log.levels.WARN then
		self.logger.fmt_warn("%s WARN: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:error(msg)
	if self.level >= vim.log.levels.ERROR then
		self.logger.fmt_error("%s ERROR: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

return Logger
