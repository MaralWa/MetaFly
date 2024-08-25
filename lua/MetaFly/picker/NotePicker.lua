local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local MetaFlyPopUp = require("MetaFly.view.MetaFlyPopUp")
local TableUtils = require("MetaFly/utils/TableUtils")

NotePiker = {}

-- our picker function: colors
NotePiker.notes = function(opts)
	-- local popup = MetaFlyPopUp:new()
	local sqlResult = io.popen(
		"echo \"select Note.title, NoteBox.path || '/' || Note.fileName  from Note, NoteBox where Note.idNoteBox = NoteBox.id;\" | sqlite3 ~/Documents/vimwiki/MetaFly/metadata.db -csv"
	)
	local notesTable = {}
	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			local title, fileName = string.match(line, "(.*)%,(.*)")
			table.insert(notesTable, { title:gsub('"', ""), fileName:gsub('"', "") })
		end
	end
	opts = opts or {}
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
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					vim.cmd.edit(selection.value[2])
				end)
				return true
			end,
		})
		:find()
end

return NotePiker
