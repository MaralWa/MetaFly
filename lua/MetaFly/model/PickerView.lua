local MetaFlyView = require("MetaFly.model.MetaFlyView")
local logger = require("MetaFly.config"):getInstance():getLogger().child("view").child("PickerView")

local PickerView = setmetatable({}, { __index = MetaFlyView })
PickerView.__index = PickerView

PickerView.columns = { { text = "Note.title" }, { file = "fullFileName" } }

setmetatable(PickerView, {
	__index = MetaFlyView, -- Inherit from MetaFlyView
})

function PickerView.getDefaultPicker()
	logger.debug("PickerView.getDefaultPicker called")
	return PickerView.new({
		name = "DefaultView",
		type = "Picker",
		description = "All Metafly notes",
		columns = PickerView.columns,
	})
end

function PickerView.new(values)
	local self = MetaFlyView.new(values)
	logger.debug("Creating new PickerView with values: " .. tostring(values))
	setmetatable(self, PickerView)
	self.columns = PickerView.columns
	if values.from ~= nil then
		for _, fromTable in ipairs(values.from) do
			if not vim.tbl_contains(self.from, fromTable) then
				table.insert(self.from, fromTable)
			end
		end
	end
	if values["where"] then
		self.where = "Note.idNoteBox = NoteBox.id and ( " .. values["where"] .. " )"
	else
		self.where = "Note.idNoteBox = NoteBox.id"
	end
	self.inherit = values["inherit"]
	return self
end

return PickerView
