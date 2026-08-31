local config = require("MetaFly.config"):getInstance()
local Utils = require("MetaFly.utils.Utils")
local picker = require("MetaFly.picker.SnacksNotePicker")

local logger = config:getLogger("NotesPickerController")

local NotesPickerController = {}

function NotesPickerController.showPicker(pickerName)
	if not pickerName then
		picker.notesView()
	end
	picker.notesView(pickerName)
end

return NotesPickerController
