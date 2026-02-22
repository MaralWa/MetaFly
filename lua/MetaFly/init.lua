local Config = require("MetaFly.config")
local SetUpController = require("MetaFly.controller.SetUpController")
local Database = require("MetaFly.model.database")

MetaFly = {}

local logger = require("MetaFly.utils.Logger")

MetaFly.options = {}
MetaFly.noteBoxes = {}

function MetaFly.setup(opts)
	Config:getInstance():setup(opts)
	local db = Database:getInstance()
	logger.info("MetaFly Database initialized at: " .. db:getUri())
	local setUpController = SetUpController:new()
	local noteboxes = setUpController:scanNoteBoxes(opts["noteBoxes"])
end

return MetaFly
