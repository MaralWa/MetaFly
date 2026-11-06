local ViewFactory = require("MetaFly.view.ViewFactory")
local pickerViewModule = require("MetaFly.model.PickerView")
local logger = require("MetaFly.config"):getInstance():getLogger().child("picker").child("SnacksNotePicker")
local SnacksNotePicker = {}

---@param fileName string|nil
SnacksNotePicker.notesView = function(fileName)
	logger.info("SnacksNotePicker.notesView called with fileName: " .. tostring(fileName))
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
		if pickerViewModule == nil then
			logger.error("Failed to load PickerView module")
			vim.notify("Failed to load PickerView module", vim.log.levels.ERROR)
			return
		end
		pickerView = pickerViewModule.getDefaultPicker()
	end

	local options = {}
	SnacksNotePicker.notes(pickerView, options)
end

SnacksNotePicker.bufferView = function()
	local bufferName = vim.api.nvim_buf_get_name(0)
	if bufferName == nil or bufferName == "" then
		logger.error("Current buffer has no name")
		vim.notify("Current buffer has no name", vim.log.levels.ERROR)
		return
	end

	local pickerView = ViewFactory.readFromBuffer(bufferName)
	if pickerView == nil then
		logger.error("Failed to load picker view from buffer: " .. bufferName)
		vim.notify("Failed to load picker view from buffer: " .. bufferName, vim.log.levels.ERROR)
		return
	end

	local options = {}
	SnacksNotePicker.notes(pickerView, options)
end

SnacksNotePicker.notes = function(pickerView, opts)
	local database = require("MetaFly.model.database"):getInstance()
	local sqlStatement = pickerView:getSelectStatement()
	logger.info("SnacksNotePicker.notes sqlStatement: " .. sqlStatement)
	local items = database:select(sqlStatement)

	logger.info("size of items: " .. #items)

	opts = opts or {}
	Snacks.picker.pick(vim.tbl_extend("keep", {
		title = pickerView.name,
		items = items,
		format = "text",
		preview = "file",
		confirm = function(picker, item)
			if not item then
				logger.error("No entry selected")
				vim.notify("No entry selected", vim.log.levels.WARN)
				return
			end
			picker:close()
			vim.schedule(function()
				vim.cmd.edit(item.file)
			end)
		end,
	}, opts))
end

return SnacksNotePicker
