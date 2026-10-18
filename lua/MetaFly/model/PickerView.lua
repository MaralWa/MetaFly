local MetaFlyView = require("MetaFly.model.MetaFlyView")
local logger = require("MetaFly.config"):getInstance():getLogger().child("view").child("PickerView")

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
	logger.debug("Creating new PickerView with values: " .. tostring(values))
	setmetatable(newObject, self)
	newObject.columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" }
	newObject.from = { "Note", "NoteBox" }
	if values.from ~= nil then
		for _, fromTable in ipairs(values.from) do
			if not vim.tbl_contains(newObject.from, fromTable) then
				table.insert(newObject.from, fromTable)
			end
		end
	end
	newObject.sqlMode = "csv"
	if values["where"] then
		newObject.where = "Note.idNoteBox = NoteBox.id and ( " .. values["where"] .. " )"
	else
		newObject.where = "Note.idNoteBox = NoteBox.id"
	end
	newObject.inherit = values["inherit"]
	return newObject
end

return PickerView
