local Config = {}

Config.__index = Config

local instance = nil

---@class MetaFly.config.NoteBox
---@field name string
---@field path string

---@class MetaFly.config
---@field database string
---@field noteBoxes MetaFly.config.NoteBox[]
---@field views string

-- Standardwerte (ptional)
local defaults = {
	enable = true,
	symbol = "🪰",
	speed = "fast",
}

local function new()
	print("new config")
	local self = setmetatable({}, Config)
	return self
end

function Config:getInstance()
	if not instance then
		instance = new()
	end
	return instance
end

---@type MetaFly.config
local DefaultConfig = {
	database = "~/.config/metafly_database.db",
	noteBoxes = {},
	views = "~/.config/views/",
}

-- setup() wird vom Benutzer aufgerufen
function Config:setup(opts)
	opts = opts or {}
	local user_config = vim.tbl_deep_extend("force", DefaultConfig, opts)
	if user_config.database ~= nil then
		self.database = user_config.database
	end
	if user_config.noteBoxes ~= nil then
		self.noteBoxes = user_config.noteBoxes
	end
	if user_config.views ~= nil then
		self.views = user_config.views
	end
end

return Config
