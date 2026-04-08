local config = require("MetaFly.config"):getInstance()
local Utils = require("MetaFly.utils.Utils")
local picker = require("MetaFly.picker.SnacksNotePicker")

local logger = config:getLogger("NotesPickerController")

local NotesPickerController = {}

function NotesPickerController.showPicker(pickerName)
	if not pickerName then
		picker.notesView()
	end
	local viewDir = config:getViewDirectory()
	if not viewDir then
		logger:error("View directory is not set in the configuration.")
		return
	end
	local fileName = Utils.findFileByBasename(viewDir, pickerName, { ".yaml", ".yml" })
	if not fileName then
		logger:error("Picker file not found: " .. pickerName)
		return
	end
	picker.notesView(fileName)
end

return NotesPickerController
