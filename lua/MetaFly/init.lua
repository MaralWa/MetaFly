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
	local setUpController = require("MetaFly.controller.SetUpController"):new()
	local noteboxes = setUpController:scanNoteBoxes(opts["noteBoxes"])
end

return MetaFly
