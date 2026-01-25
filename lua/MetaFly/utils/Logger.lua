local Logger = {}

Logger.config = {
	title = "MetaFly",
	level = vim.log.levels.INFO, -- Loggerindest-Level
	debug = false,
}

local function get_notifier()
	local ok, notify = pcall(require, "notify")
	if ok then
		return notify
	end
	return vim.notify
end

local notify = get_notifier()

local function should_log(level)
	if Logger.config.debug then
		return true
	end
	return level >= Logger.config.level
end

function Logger.log(msg, level, opts)
	level = level or vim.log.levels.INFO
	opts = opts or {}

	if not should_log(level) then
		return
	end

	opts.title = opts.title or Logger.config.title
	notify(msg, level, opts)
end

-- Convenience Wrapper
function Logger.debug(msg, opts)
	Logger.log(msg, vim.log.levels.DEBUG, opts)
end

function Logger.info(msg, opts)
	Logger.log(msg, vim.log.levels.INFO, opts)
end

function Logger.warn(msg, opts)
	Logger.log(msg, vim.log.levels.WARN, opts)
end

function Logger.error(msg, opts)
	Logger.log(msg, vim.log.levels.ERROR, opts)
end

return Logger
