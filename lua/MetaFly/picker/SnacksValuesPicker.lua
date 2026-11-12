local SnacksValuesPicker = {}

---@param values string[]
SnacksValuesPicker.open = function(values)
	if type(values) ~= "table" then
		vim.notify("Values must be a list of strings", vim.log.levels.ERROR)
		return
	end

	local items = {}
	for index, value in ipairs(values) do
		if type(value) ~= "string" or value:find("[\r\n]") then
			vim.notify("Values must be single-line strings", vim.log.levels.ERROR)
			return
		end
		table.insert(items, { text = value, _select_key = tostring(index) })
	end
	if #items == 0 then
		vim.notify("No values available for picker", vim.log.levels.WARN)
		return
	end

	local buffer = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)

	local function insert(picker, item, markdown)
		local selected = picker:selected()
		if #selected == 0 and item then
			selected = { item }
		end
		if #selected == 0 then
			vim.notify("No value selected", vim.log.levels.WARN)
			return
		end

		local lines = {}
		for _, selectedItem in ipairs(selected) do
			table.insert(lines, (markdown and "- " or "") .. selectedItem.text)
		end
		if not markdown then
			lines = { table.concat(lines, ", ") }
		end

		picker:close()
		if not vim.api.nvim_buf_is_valid(buffer) or not vim.api.nvim_buf_is_loaded(buffer) then
			vim.notify("The original buffer is no longer available", vim.log.levels.ERROR)
			return
		end
		local ok, err = pcall(vim.api.nvim_buf_set_text, buffer, cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2], lines)
		if not ok then
			vim.notify("Failed to insert selected values: " .. tostring(err), vim.log.levels.ERROR)
		end
	end

	Snacks.picker.pick({
		title = "Values",
		items = items,
		format = "text",
		confirm = function(picker, item)
			insert(picker, item, false)
		end,
		actions = {
			insert_markdown = function(picker, item)
				insert(picker, item, true)
			end,
		},
		win = {
			input = {
				keys = {
					["<c-x>"] = { "insert_markdown", mode = { "n", "i" }, desc = "Insert Markdown list" },
				},
			},
			list = {
				keys = {
					["<c-x>"] = { "insert_markdown", mode = "n", desc = "Insert Markdown list" },
				},
			},
		},
	})
end

return SnacksValuesPicker
