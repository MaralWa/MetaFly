local config = require("MetaFly.config"):getInstance()
local ViewFactory = require("MetaFly.view.ViewFactory")
local pickerView = require("MetaFly.model.PickerView")
local picker = require("MetaFly.picker.SnacksNotePicker")

local logger = config:getLogger().child("controller").child("NotesPickerController")

local NotesPickerController = {}

function NotesPickerController.showBufferPicker()
	picker.bufferView()
end

function NotesPickerController.showPicker(pickerName)
	local view = NotesPickerController.createPickerview(pickerName)
	local options = {}
	picker.notes(view, options)
end

function NotesPickerController.createPickerview(fileName)
	logger.info("called with fileName: " .. tostring(fileName))
	if fileName ~= nil and fileName ~= "" then
		local view = ViewFactory.readFromFile(fileName)
		if view == nil then
			logger.error("Failed to load picker view from file: " .. fileName)
			vim.notify("Failed to load picker view from file: " .. fileName, vim.log.levels.ERROR)
			return
		end
		return view
	else
		logger.info("No fileName provided, using default picker view")
		if pickerView == nil then
			logger.error("Failed to load PickerView module")
			vim.notify("Failed to load PickerView module", vim.log.levels.ERROR)
			return
		end
		return pickerView.getDefaultPicker()
	end
end

return NotesPickerController
