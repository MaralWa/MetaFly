local config = require("MetaFly.config"):getInstance()
local ViewFactory = require("MetaFly.view.ViewFactory")
local pickerView = require("MetaFly.model.PickerView")
local Utils = require("MetaFly.utils.Utils")
local picker = require("MetaFly.picker.SnacksNotePicker")

local logger = config:getLogger("NotesPickerController")

local NotesPickerController = {}

function NotesPickerController.showBufferPicker()
	picker.bufferView()
end

function NotesPickerController.showPicker(pickerName)
  local pickerView = NotesPickerController.createPickerview(pickerName)
	local options = {}
	picker.notes(pickerView, options)
end

function NotesPickerController.createPickerview(fileName)
	logger.info("called with fileName: " .. tostring(fileName))
	local pickerView = nil
	if fileName ~= nil and fileName ~= "" then
		pickerView = ViewFactory.readFromFile(fileName)
		if pickerView == nil then
			logger.error("Failed to load picker view from file: " .. fileName)
			vim.notify("Failed to load picker view from file: " .. fileName, vim.log.levels.ERROR)
			return
		end
	else
		logger.info("No fileName provided, using default picker view")
		if pickerView == nil then
			logger.error("Failed to load PickerView module")
			vim.notify("Failed to load PickerView module", vim.log.levels.ERROR)
			return
		end
		return = pickerView.getDefaultPicker()
	end
end

return NotesPickerController
