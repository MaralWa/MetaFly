local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local ViewFactory = require("MetaFly.view.ViewFactory")
local logger = require("MetaFly/utils/Logger")

NotePicker = {}

---@param fileName string, nil
NotePicker.notesView = function(fileName)
	local pickerView = nil
	if fileName ~= nil then
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
	NotePicker.notes(pickerView, options)
end

NotePicker.notes = function(pickerView, opts)
	local database = require("MetaFly.model.database"):getInstance()
	local sqlStatement = pickerView:getSelectStatement()
	logger.info("NotePicker.notes sqlStatement: " .. sqlStatement)
	local sqlResult = database:callSql(pickerView:getSelectStatement(), pickerView.sqlMode)
	local notesTable = {}
	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			local title, fileName = string.match(line, "(.*)%,(.*)")
			table.insert(notesTable, { title:gsub('"', ""), fileName:gsub('"', "") })
		end
	end
	logger.info("size of notesTable: " .. #notesTable)
	print("size of notesTable: " .. #notesTable)
	opts = opts and opts or {}
	-- local opts = {}
	local picker = pickers.new(opts, {
		prompt_title = pickerView.name,
		finder = finders.new_table({
			results = notesTable,
			entry_maker = function(entry)
				return {
					value = entry,
					display = entry[1],
					ordinal = entry[1],
					sort = entry[1],
					filename = entry[2],
				}
			end,
		}),
		sorter = conf.generic_sorter(opts),
		previewer = conf.file_previewer(opts),

		attach_mappings = function(prompt_bufnr, map)
			local function open_file()
				local selection = action_state.get_selected_entry()
				if selection == nil then
					logger.error("No entry selected")
					vim.notify("No entry selected", vim.log.levels.WARN)
					return
				end
				actions.close(prompt_bufnr)
				vim.cmd.edit(selection.filename)
			end

			-- KRITISCH: Ersetzen Sie die Default-Action
			actions.select_default:replace(open_file)

			map("i", "<CR>", open_file)
			map("n", "<CR>", open_file)

			return true
		end,
	})

	picker:find()
end

return NotePicker
