local MetaFlyView = require("MetaFly.model.MetaFlyView")
local logger = require("MetaFly.config"):getInstance():getLogger("PickerView")

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
	logger:debug("PickerView:new with values: " .. vim.inspect(values))
	local newObject = MetaFlyView.new(self, values)
	setmetatable(newObject, self)
	newObject.columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" }
	newObject.from = { "Note", "NoteBox" }
	newObject.sqlMode = "csv"
	newObject.where = "Note.idNoteBox = NoteBox.id and ( " .. values["where"] .. " )"
	logger:debug("Created PickerView with name: " .. newObject.name .. " and where clause: " .. newObject.where)
	return newObject
end

return PickerView
