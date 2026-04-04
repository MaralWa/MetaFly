local ViewFactory = require("MetaFly.view.ViewFactory")
local logger = require("MetaFly.config"):getInstance():getLogger()

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
		pickerView = require("MetaFly.model.PickerView").DefaultPicker
	end

	local options = {}
	SnacksNotePicker.notes(pickerView, options)
end

SnacksNotePicker.notes = function(pickerView, opts)
	local database = require("MetaFly.model.database"):getInstance()
	local sqlStatement = pickerView:getSelectStatement()
	logger.info("SnacksNotePicker.notes sqlStatement: " .. sqlStatement)
	local sqlResult = database:callSql(pickerView:getSelectStatement(), pickerView.sqlMode)

	local items = {}
	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			local title, fileName = string.match(line, "(.*)%,(.*)")
			if title and fileName then
				table.insert(items, {
					text = title:gsub('"', ""),
					file = fileName:gsub('"', ""),
				})
			end
		end
	end
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
