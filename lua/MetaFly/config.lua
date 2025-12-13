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
	self.logger = require("logger"):new({ log_level = "debug", prefix = "MetaFly", echo_messages = false })
	return self
end

function Config:getInstance()
	if not instance then
		instance = new()
	end
	return instance
end

function Config:getLogger()
	return self.logger
end

---@type MetaFly.config
local DefaultConfig = {
	database = "~/.config/metafly_database.db",
	noteBoxes = {},
	views = "~/.config/views/",
}

-- setup() wird vom Benutzer aufgerufen
---@param user_config MetaFly.config
function Config:setup(user_config)
	if user_config["database"] then
		self.database = user_config["database"]
	end
	if user_config.noteBoxes ~= nil then
		self.database = user_config.database
	end
	if user_config.views ~= nil then
		self.views = user_config.views
	end
end

return Config
