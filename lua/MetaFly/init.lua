local database = require("MetaFly.model.database")
local SetUpController = require("MetaFly.controller.SetUpController")

MetaFly = {}

MetaFly.options = {}
MetaFly.noteBoxes = {}

function MetaFly.setup(opts)
	MetaFly.options = opts
	database:init(MetaFly.options["database"])
	local setUpController = SetUpController:new()
	MetaFly.noteBoxes = setUpController:scanNoteBoxes(opts["noteBoxes"])
end

return MetaFly
