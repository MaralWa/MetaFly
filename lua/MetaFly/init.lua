local Config = require("MetaFly.config")
local SetUpController = require("MetaFly.controller.SetUpController")
local Database = require("MetaFly.model.database")

MetaFly = {}

-- Standard-Config
local default_config = {}

local logger = require("MetaFly.utils.Logger")

MetaFly.config = vim.deepcopy(default_config)

MetaFly.options = {}
MetaFly.noteBoxes = {}

function MetaFly.setup(opts)
	Config:getInstance():setup(opts)
	local db = Database:getInstance()
	db:init(MetaFly.config)
	logger.info("MetaFly Database initialized at: " .. db:getUri())
	print("MetaFly init: " .. db:getUri())
	local setUpController = SetUpController:new()
	local noteboxes = setUpController:scanNoteBoxes(opts["noteBoxes"])
end

return MetaFly
