-- lua/myplugin/logger.lua
--
-- Log4J-style logger for Neovim/LuaJIT.
--
-- Features:
--   * trace / debug / info / warn / error / fatal
--   * configurable log level
--   * file logging
--   * size-based log rotation
--   * configurable number of retained log files
--   * automatic deletion of old files
--   * timestamps
--   * logger names / contexts
--   * child loggers
--   * printf-style formatting
--   * safe operation: logging errors never crash the plugin
--
-- Example:
--
-- local logger = require("myplugin.logger")
--
-- logger.setup({
--   name = "myplugin",
--   level = "debug",
--   file = vim.fn.stdpath("log") .. "/myplugin.log",
--   rotation = {
--     max_size = 10 * 1024 * 1024,
--     max_files = 5,
--   },
-- })
--
-- local lsp = logger.child("lsp")
-- local config = logger.child("config")
--
-- lsp.debug("Received response")
-- config.info("Configuration loaded")
--
-- Output:
--
-- 2026-09-13 16:42:31.123 DEBUG [myplugin.lsp] Received response
-- 2026-09-13 16:42:31.124 INFO  [myplugin.config] Configuration loaded

local M = {}

local uv = vim.uv or vim.loop

-----------------------------------------------------------------------
-- Log levels
-----------------------------------------------------------------------

local LEVELS = {
	trace = 10,
	debug = 20,
	info = 30,
	warn = 40,
	error = 50,
	fatal = 60,
}

local LEVEL_NAMES = {
	[10] = "TRACE",
	[20] = "DEBUG",
	[30] = "INFO ",
	[40] = "WARN ",
	[50] = "ERROR",
	[60] = "FATAL",
}

-----------------------------------------------------------------------
-- Default configuration
-----------------------------------------------------------------------
local defaults = {
	name = "nvim",
	level = "info",
	file = nil,

	rotation = {
		enabled = true,

		-- Maximum size of the active logfile.
		max_size = 10 * 1024 * 1024,

		-- Number of rotated files to retain.
		--
		-- 0 = no backups
		-- 5 = .1 ... .5
		max_files = 5,
	},

	timestamp = true,

	-- Flush after every write.
	flush = true,
}

-----------------------------------------------------------------------
-- Runtime state
-----------------------------------------------------------------------

local config = vim.deepcopy(defaults)

local initialized = false
local file_handle = nil
local current_size = 0

-- Prevent recursive logger failures.
local in_write = false

-----------------------------------------------------------------------
-- Utility functions
-----------------------------------------------------------------------

local function stderr(message)
	-- Logging must never crash the plugin.
	--
	-- vim.notify() itself can potentially be unavailable during very
	-- early startup/shutdown, so protect it as well.
	pcall(function()
		vim.schedule(function()
			pcall(vim.notify, "[logger] " .. tostring(message), vim.log.levels.DEBUG)
		end)
	end)
end

local function merge_config(user_config)
	local result = vim.deepcopy(defaults)

	if type(user_config) ~= "table" then
		return result
	end

	for key, value in pairs(user_config) do
		if key ~= "rotation" then
			result[key] = value
		end
	end

	if type(user_config.rotation) == "table" then
		for key, value in pairs(user_config.rotation) do
			result.rotation[key] = value
		end
	end

	return result
end

local function normalize_level(level)
	if type(level) == "number" then
		return level
	end

	if type(level) ~= "string" then
		return LEVELS.info
	end

	return LEVELS[level:lower()] or LEVELS.info
end

local function dirname(path)
	return vim.fn.fnamemodify(path, ":h")
end

local function ensure_directory(path)
	local directory = dirname(path)

	if directory == "." or directory == "" then
		return true
	end

	local stat = uv.fs_stat(directory)

	if stat then
		return stat.type == "directory"
	end

	local ok, err = pcall(vim.fn.mkdir, directory, "p")

	if not ok then
		stderr("Could not create log directory: " .. tostring(err))
		return false
	end

	return true
end

local function file_size(path)
	local stat = uv.fs_stat(path)

	if not stat then
		return 0
	end

	return stat.size or 0
end

-----------------------------------------------------------------------
-- File handling
-----------------------------------------------------------------------

local function close_file()
	if not file_handle then
		return
	end

	pcall(function()
		file_handle:flush()
	end)

	pcall(function()
		file_handle:close()
	end)

	file_handle = nil
end

local function open_file()
	if not config.file then
		return false
	end

	if file_handle then
		return true
	end

	if not ensure_directory(config.file) then
		return false
	end

	local handle, err = io.open(config.file, "a")

	if not handle then
		stderr("Could not open logfile: " .. tostring(err))
		return false
	end

	file_handle = handle
	current_size = file_size(config.file)

	return true
end

local function remove_file(path)
	if not uv.fs_stat(path) then
		return true
	end

	local ok, err = os.remove(path)

	if not ok then
		stderr("Could not remove logfile '" .. path .. "': " .. tostring(err))

		return false
	end

	return true
end

-----------------------------------------------------------------------
-- Rotation
-----------------------------------------------------------------------

local function rotate()
	if not config.file then
		return true
	end

	if not config.rotation.enabled then
		return true
	end

	local max_files = math.max(0, math.floor(tonumber(config.rotation.max_files) or defaults.rotation.max_files))

	close_file()

	--
	-- max_files == 0
	--
	-- Just delete the current logfile and create a new one.
	--
	if max_files == 0 then
		remove_file(config.file)

		current_size = 0

		return open_file()
	end

	--
	-- Delete oldest backup.
	--
	-- myplugin.log.5 -> deleted
	--
	local oldest = string.format("%s.%d", config.file, max_files)

	remove_file(oldest)

	--
	-- Shift backups.
	--
	-- .4 -> .5
	-- .3 -> .4
	-- .2 -> .3
	-- .1 -> .2
	--
	for index = max_files - 1, 1, -1 do
		local source = string.format("%s.%d", config.file, index)

		local target = string.format("%s.%d", config.file, index + 1)

		if uv.fs_stat(source) then
			local ok, err = os.rename(source, target)

			if not ok then
				stderr(string.format("Could not rotate '%s' -> '%s': %s", source, target, tostring(err)))
			end
		end
	end

	--
	-- Current logfile becomes .1.
	--
	if uv.fs_stat(config.file) then
		local target = config.file .. ".1"

		local ok, err = os.rename(config.file, target)

		if not ok then
			stderr(string.format("Could not rotate '%s' -> '%s': %s", config.file, target, tostring(err)))

			current_size = file_size(config.file)

			return open_file()
		end
	end

	current_size = 0

	return open_file()
end

local function ensure_capacity(bytes_to_write)
	if not config.file then
		return true
	end

	if not config.rotation.enabled then
		return true
	end

	local max_size = tonumber(config.rotation.max_size)

	if not max_size or max_size <= 0 then
		return true
	end

	--
	-- Rotate BEFORE writing the entry.
	--
	if current_size > 0 and current_size + bytes_to_write > max_size then
		return rotate()
	end

	return true
end

-----------------------------------------------------------------------
-- Formatting
-----------------------------------------------------------------------

local function format_message(...)
	local argc = select("#", ...)

	if argc == 0 then
		return ""
	end

	local first = select(1, ...)

	--
	-- logger.info(non_string_value, ...)
	--
	if type(first) ~= "string" then
		local values = {}

		for index = 1, argc do
			values[#values + 1] = tostring(select(index, ...))
		end

		return table.concat(values, " ")
	end

	--
	-- logger.info("hello")
	--
	if argc == 1 then
		return first
	end

	--
	-- logger.info("value = %s", value)
	--
	local args = {}

	for index = 2, argc do
		args[#args + 1] = select(index, ...)
	end

	local ok, result = pcall(string.format, first, unpack(args))

	if ok then
		return result
	end

	--
	-- Never let an invalid format string break the plugin.
	--
	local values = { first }

	for index = 1, #args do
		values[#values + 1] = tostring(args[index])
	end

	return table.concat(values, " ")
end

local function timestamp()
	if not config.timestamp then
		return ""
	end

	--
	-- os.date() provides the seconds.
	-- hrtime() gives us a monotonic clock for milliseconds.
	--
	local milliseconds = math.floor((uv.hrtime() / 1e6) % 1000)

	return os.date("%Y-%m-%d %H:%M:%S") .. string.format(".%03d", milliseconds)
end

local function format_line(logger_name, level, message)
	local parts = {}

	if config.timestamp then
		parts[#parts + 1] = timestamp()
	end

	parts[#parts + 1] = LEVEL_NAMES[level] or "?????"

	parts[#parts + 1] = "[" .. logger_name .. "]"

	parts[#parts + 1] = message

	return table.concat(parts, " ") .. "\n"
end

-----------------------------------------------------------------------
-- Writing
-----------------------------------------------------------------------

local function write_line(line)
	if not config.file then
		return true
	end

	if not open_file() then
		return false
	end

	local bytes = #line

	if not ensure_capacity(bytes) then
		return false
	end

	--
	-- Rotation may have closed/reopened the file.
	--
	if not file_handle and not open_file() then
		return false
	end

	local ok, err = pcall(function()
		file_handle:write(line)

		if config.flush then
			file_handle:flush()
		end
	end)

	if not ok then
		stderr("Could not write logfile: " .. tostring(err))
		return false
	end

	current_size = current_size + bytes

	return true
end

-----------------------------------------------------------------------
-- Logger implementation
-----------------------------------------------------------------------

local function create_logger(name)
	local logger = {}

	--
	-- Full logger name.
	--
	-- Example:
	--
	--   myplugin
	--   myplugin.lsp
	--   myplugin.lsp.client
	--
	logger.name = name

	local function write(level, ...)
		if level < normalize_level(config.level) then
			return
		end

		if in_write then
			return
		end

		in_write = true

		local args = { ... }
		local ok, err = pcall(function()
			local message = format_message(unpack(args))

			local line = format_line(logger.name, level, message)

			write_line(line)
		end)

		in_write = false

		if not ok then
			stderr("Logging failed: " .. tostring(err))
		end
	end

	---------------------------------------------------------------------
	-- Logging methods
	---------------------------------------------------------------------

	function logger.trace(...)
		write(LEVELS.trace, ...)
	end

	function logger.debug(...)
		write(LEVELS.debug, ...)
	end

	function logger.info(...)
		write(LEVELS.info, ...)
	end

	function logger.warn(...)
		write(LEVELS.warn, ...)
	end

	function logger.error(...)
		write(LEVELS.error, ...)
	end

	function logger.fatal(...)
		write(LEVELS.fatal, ...)
	end

	---------------------------------------------------------------------
	-- Aliases
	---------------------------------------------------------------------

	logger.warning = logger.warn
	logger.critical = logger.fatal

	---------------------------------------------------------------------
	-- Level handling
	---------------------------------------------------------------------

	function logger.is_enabled(level)
		return normalize_level(level) >= normalize_level(config.level)
	end

	function logger.set_level(level)
		config.level = normalize_level(level)
	end

	function logger.get_level()
		return config.level
	end

	---------------------------------------------------------------------
	-- Child logger
	---------------------------------------------------------------------
	--
	-- Example:
	--
	-- local lsp = logger.child("lsp")
	-- local client = lsp.child("client")
	--
	-- Result:
	--
	-- [myplugin.lsp]
	-- [myplugin.lsp.client]
	--
	---------------------------------------------------------------------

	function logger.child(child_name)
		if child_name == nil or tostring(child_name) == "" then
			return logger
		end

		child_name = tostring(child_name)

		return create_logger(logger.name .. "." .. child_name)
	end

	---------------------------------------------------------------------
	-- Context alias
	---------------------------------------------------------------------

	logger.context = logger.child

	return logger
end

-----------------------------------------------------------------------
-- Root logger
-----------------------------------------------------------------------

local root_logger = create_logger(config.name)

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- Configure the root logger.
---
---@param user_config table|nil
---@return table logger
function M.setup(user_config)
	close_file()

	config = merge_config(user_config)

	config.level = normalize_level(config.level)

	if config.rotation.max_size ~= nil then
		config.rotation.max_size = tonumber(config.rotation.max_size) or defaults.rotation.max_size
	end

	if config.rotation.max_files ~= nil then
		config.rotation.max_files = tonumber(config.rotation.max_files) or defaults.rotation.max_files
	end

	initialized = true

	--
	-- Recreate root logger because its name comes from config.
	--
	root_logger = create_logger(config.name)

	if config.file then
		open_file()
	end

	return root_logger
end

--- Get the root logger.
---
---@return table
function M.get_logger()
	return root_logger
end

--- Create a child logger from the root logger.
---
---@param name string
---@return table
function M.child(name)
	return root_logger.child(name)
end

--- Alias for child().
function M.context(name)
	return root_logger.child(name)
end

--- Return a copy of the current configuration.
---
---@return table
function M.get_config()
	return vim.deepcopy(config)
end

--- Set the global log level.
---
---@param level string|number
function M.set_level(level)
	config.level = normalize_level(level)
end

--- Get the global log level.
---
---@return number
function M.get_level()
	return config.level
end

--- Check whether a level is enabled.
---
---@param level string|number
---@return boolean
function M.is_enabled(level)
	return normalize_level(level) >= normalize_level(config.level)
end

--- Flush the logfile.
function M.flush()
	if file_handle then
		pcall(function()
			file_handle:flush()
		end)
	end
end

--- Close the logfile.
function M.close()
	close_file()
end

--- Reopen the logfile.
function M.reopen()
	close_file()

	current_size = 0

	if config.file then
		return open_file()
	end

	return true
end

--- Force a logfile rotation.
function M.rotate()
	return rotate()
end

--- Return whether the logger has been initialized.
function M.is_initialized()
	return initialized
end

-----------------------------------------------------------------------
-- Root logger methods
-----------------------------------------------------------------------
--
-- This allows:
--
--   local logger = require("myplugin.logger")
--
--   logger.info("hello")
--
-- instead of requiring:
--
--   local logger = require("myplugin.logger").get_logger()
--
-----------------------------------------------------------------------

M.trace = function(...)
	root_logger.trace(...)
end

M.debug = function(...)
	root_logger.debug(...)
end

M.info = function(...)
	root_logger.info(...)
end

M.warn = function(...)
	root_logger.warn(...)
end

M.warning = M.warn

M.error = function(...)
	root_logger.error(...)
end

M.fatal = function(...)
	root_logger.fatal(...)
end

M.critical = M.fatal

return M
