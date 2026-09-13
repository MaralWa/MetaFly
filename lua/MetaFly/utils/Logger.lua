-- lua/myplugin/logger.lua
--
-- A small Log4J-style logger for Neovim/LuaJIT.
--
-- Features:
--   * trace / debug / info / warn / error / fatal
--   * configurable log level
--   * file logging
--   * size-based log rotation
--   * configurable number of retained log files
--   * automatic deletion of old files
--   * timestamps
--   * logger name
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
-- logger.debug("value = %s", value)
-- logger.info("Plugin started")
-- logger.warn("Something looks suspicious")
-- logger.error("Failed to load %s", filename)

local M = {}

local uv = vim.uv or vim.loop

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

local defaults = {
	name = "nvim",
	level = "info",
	file = nil,

	-- File rotation.
	rotation = {
		enabled = true,

		-- Maximum size of the active logfile.
		max_size = 10 * 1024 * 1024,

		-- Number of rotated files to retain.
		--
		-- 0 = no rotated files
		-- 5 = logfile + .1 ... .5
		max_files = 5,
	},

	-- Include milliseconds in timestamps.
	timestamp = true,

	-- Flush after every write.
	--
	-- true:
	--   safer if Neovim crashes, but slightly more filesystem activity.
	--
	-- false:
	--   better performance, but buffered writes may be lost on crash.
	flush = true,
}

local config = vim.deepcopy(defaults)

local initialized = false
local file_handle = nil
local current_size = 0
local in_write = false

local function stderr(message)
	-- Never let logging itself crash the application.
	vim.schedule(function()
		vim.notify("[logger] " .. tostring(message), vim.log.levels.DEBUG)
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
	if uv.fs_stat(path) then
		local ok, err = os.remove(path)

		if not ok then
			stderr("Could not remove logfile '" .. path .. "': " .. tostring(err))
			return false
		end
	end

	return true
end

local function rotate()
	if not config.file then
		return true
	end

	if not config.rotation.enabled then
		return true
	end

	local max_files = math.max(0, math.floor(tonumber(config.rotation.max_files) or 0))

	close_file()

	-- No backups requested:
	--
	--   myplugin.log
	--
	-- simply gets replaced by a new empty logfile.
	if max_files == 0 then
		remove_file(config.file)

		current_size = 0
		return open_file()
	end

	-- Delete the oldest logfile first.
	--
	-- myplugin.log.5 -> deleted
	if max_files >= 1 then
		local oldest = string.format("%s.%d", config.file, max_files)

		remove_file(oldest)
	end

	-- Shift existing files:
	--
	-- .4 -> .5
	-- .3 -> .4
	-- .2 -> .3
	-- .1 -> .2
	-- current -> .1
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

	-- Current logfile becomes .1.
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

	-- If the current logfile already contains data and adding the new
	-- entry would exceed the configured limit, rotate first.
	if current_size > 0 and current_size + bytes_to_write > max_size then
		return rotate()
	end

	return true
end

local function format_message(...)
	local argc = select("#", ...)

	if argc == 0 then
		return ""
	end

	local first = select(1, ...)

	if type(first) ~= "string" then
		local values = {}

		for i = 1, argc do
			values[#values + 1] = tostring(select(i, ...))
		end

		return table.concat(values, " ")
	end

	if argc == 1 then
		return first
	end

	local args = {}

	for i = 2, argc do
		args[#args + 1] = select(i, ...)
	end

	local ok, result = pcall(string.format, first, unpack(args))

	if ok then
		return result
	end

	-- Don't let a malformed format string break the plugin.
	local values = { first }

	for i = 1, #args do
		values[#values + 1] = tostring(args[i])
	end

	return table.concat(values, " ")
end

local function timestamp()
	if not config.timestamp then
		return ""
	end

	local now = uv.hrtime()
	local milliseconds = math.floor((now / 1e6) % 1000)

	return os.date("%Y-%m-%d %H:%M:%S") .. string.format(".%03d", milliseconds)
end

local function format_line(level, message)
	local parts = {}

	if config.timestamp then
		parts[#parts + 1] = timestamp()
	end

	parts[#parts + 1] = LEVEL_NAMES[level] or "?????"
	parts[#parts + 1] = "[" .. config.name .. "]"
	parts[#parts + 1] = message

	return table.concat(parts, " ") .. "\n"
end

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

	-- Rotation may have closed/reopened the file.
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

local function log(level, ...)
	if level < normalize_level(config.level) then
		return
	end

	-- Prevent recursive logging if something goes wrong inside the logger.
	if in_write then
		return
	end

	in_write = true

	local ok, err = pcall(function()
		local message = format_message(...)

		local line = format_line(level, message)

		write_line(line)
	end)

	in_write = false

	if not ok then
		stderr("Logging failed: " .. tostring(err))
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- Configure the logger.
---
---@param user_config table|nil
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

	if config.file then
		open_file()
	end

	return M
end

--- Return the current logger configuration.
function M.get_config()
	return vim.deepcopy(config)
end

--- Set the log level at runtime.
---
---@param level string|number
function M.set_level(level)
	config.level = normalize_level(level)
end

--- Return the current numeric log level.
function M.get_level()
	return config.level
end

--- Check whether a log level is enabled.
---
---@param level string|number
---@return boolean
function M.is_enabled(level)
	return normalize_level(level) >= normalize_level(config.level)
end

function M.trace(...)
	log(LEVELS.trace, ...)
end

function M.debug(...)
	log(LEVELS.debug, ...)
end

function M.info(...)
	log(LEVELS.info, ...)
end

function M.warn(...)
	log(LEVELS.warn, ...)
end

function M.error(...)
	log(LEVELS.error, ...)
end

function M.fatal(...)
	log(LEVELS.fatal, ...)
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
---
--- Useful if the logfile was externally moved/deleted.
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

--- Return whether the logger has been configured.
function M.is_initialized()
	return initialized
end

-- Convenience aliases matching some common logger APIs.
M.warning = M.warn
M.critical = M.fatal

return M
