local database = require("MetaFly.model.database")
local NoteBox = require("MetaFly.model.NoteBox")
local MetaFlyPopUp = require("MetaFly.view.MetaFlyPopUp")

MetaFly = {}

MetaFly.options = {}
MetaFly.noteBoxes = {}

function MetaFly.setup(opts)
	local popup = MetaFlyPopUp:new()
	popup:appendLine("Setting up MetaFly")
	popup:open()

	MetaFly.options = opts
	database:init(MetaFly.options["database"])
	for index, noteBoxConfig in ipairs(MetaFly.options["noteBoxes"]) do
		local path = noteBoxConfig["path"]
		local noteBox = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
		popup:appendLine(noteBox:getName() .. ": " .. noteBox:getPath())
		--MetaFly.noteBoxes[path] = noteBox
	end
end

return MetaFly
