local MetaFlyView = require("MetaFly.model.MetaFlyView")
local logger = require("MetaFly.config"):getInstance():getLogger("PickerView")

PickerView = {}
PickerView.__index = PickerView

setmetatable(PickerView, {
	__index = MetaFlyView, -- Inherit from MetaFlyView
})

function PickerView.getDefaultPicker()
	logger.debug("PickerView.getDefaultPicker called")
	return PickerView:new({
		name = "DefaultView",
		type = "Picker",
		description = "All Metafly notes",
		columns = { "Note.title", "fullFileName" },
		sqlMode = "csv",
	})
end

function PickerView:new(values)
	local newObject = MetaFlyView.new(self, values)
	setmetatable(newObject, self)
	newObject.columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" }
	newObject.from = { "Note", "NoteBox" }
	newObject.sqlMode = "csv"
	if values["where"] then
		newObject.where = "Note.idNoteBox = NoteBox.id and ( " .. values["where"] .. " )"
	else
		newObject.where = "Note.idNoteBox = NoteBox.id"
	end
	newObject.inherit = values["inherit"]
	logger.debug(
		"Created PickerView with name: " .. newObject.name .. " and where clause: " .. tostring(newObject.where)
	)
	return newObject
end

return PickerView
