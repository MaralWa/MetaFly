local MetaFlyView = require("MetaFly.model.MetaFlyView")

PickerView = {}
PickerView.__index = PickerView

setmetatable(PickerView, {
	__index = MetaFlyView, -- Inherit from MetaFlyView
})

---@type MetaFlyView
MetaFlyView.DefaultPicker = PickerView:new({
	name = "DefaultView",
	type = "Picker",
	description = "All Metafly notes",
	columns = { "Note.title", "fullFileName" },
	sqlMode = "csv",
})

function PickerView:new(values)
	local newObject = MetaFlyView.new(self, values)
	setmetatable(newObject, self)
	newObject.columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" }
	newObject.from = "Note, NoteBox"
	newObject.sqlMode = "csv"
	newObject.where = "Note.idNoteBox = NoteBox.id and ( " .. values["where"] .. " )"
	return newObject
end

return PickerView
