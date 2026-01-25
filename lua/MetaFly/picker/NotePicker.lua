local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local MetaFlyView = require("MetaFly/model/MetaFlyView")
local logger = require("MetaFly/utils/Logger")

NotePiker = {}

---@param fileName string, nil
NotePiker.notesView = function(fileName)
	local pickerView = nil
	if fileName ~= nil then
		pickerView = MetaFlyView:readFromFile(fileName)
	else
		pickerView = require("MetaFly.model.PickerView").DefaultPicker
	end

	local options = {}
	NotePiker.notes(pickerView, options)
end

NotePiker.notes = function(pickerView, opts)
	local database = require("MetaFly.model.database"):getInstance()
	local sqlStatement = pickerView:getSelectStatement()
	logger.info("NotePiker.notes sqlStatement: " .. sqlStatement)
	local sqlResult = database:callSql(pickerView:getSelectStatement(), pickerView.sqlMode)
	local notesTable = {}
	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			local title, fileName = string.match(line, "(.*)%,(.*)")
			table.insert(notesTable, { title:gsub('"', ""), fileName:gsub('"', "") })
		end
	end
	opts = opts and opts or {}
	-- local opts = {}
	pickers
		.new(opts, {
			prompt_title = "notes",
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
					actions.close(prompt_bufnr)
					vim.cmd.edit(selection.value[2])
				end

				map("i", "<CR>", open_file)
				map("n", "<CR>", open_file)

				-- actions.select_default:replace(function()
				-- 	local selection = action_state.get_selected_entry()
				-- 	actions.close(prompt_bufnr)
				-- 	vim.cmd.edit(selection.value[2])
				-- end)
				return true
			end,
		})
		:find()
end

return NotePiker
