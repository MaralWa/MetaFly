local Logger = {}

local instance = nil

-- Capture vim.log.levels values as local constants before plenary.log may modify them
local LOG_LEVELS = {
	TRACE = vim.log.levels.TRACE,
	DEBUG = vim.log.levels.DEBUG,
	INFO = vim.log.levels.INFO,
	WARN = vim.log.levels.WARN,
	ERROR = vim.log.levels.ERROR,
	OFF = vim.log.levels.OFF,
}

-- plenary.log expects lowercase string level names
local PLENARY_LEVEL_MAP = {
	TRACE = "trace",
	DEBUG = "debug",
	INFO = "info",
	WARN = "warn",
	ERROR = "error",
	OFF = "off",
}

---@param opts MetaFly.config.Logger | nil
local function new()
	local self = setmetatable({}, { __index = Logger })
	local config = require("MetaFly.config"):getInstance().logger
	self.level = LOG_LEVELS[config.level] or LOG_LEVELS.ERROR
	self.logger = require("plenary.log").new({
		plugin = "my_plugin",
		level = PLENARY_LEVEL_MAP[config.level] or "error",
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
	if self.level <= LOG_LEVELS.DEBUG then
		self.logger.fmt_debug("%s DEBUG: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:info(msg)
	if self.level <= LOG_LEVELS.INFO then
		self.logger.fmt_info("%s INFO: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:warn(msg)
	if self.level <= LOG_LEVELS.WARN then
		self.logger.fmt_warn("%s WARN: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

function Logger:error(msg)
	if self.level <= LOG_LEVELS.ERROR then
		self.logger.fmt_error("%s ERROR: %s", os.date("%Y-%m-%d %H:%M:%S"), msg)
	end
end

return Logger
