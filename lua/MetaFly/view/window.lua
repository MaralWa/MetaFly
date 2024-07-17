local api = vim.api
local buf, win

local window = {}

function window.center(str)
	local width = api.nvim_win_get_width(0)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

function window.open_window()
	buf = api.nvim_create_buf(false, true)
	print(buf)
	local border_buf = api.nvim_create_buf(false, true)

	api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	api.nvim_buf_set_option(buf, "filetype", "whid")

	local width = api.nvim_get_option("columns")
	local height = api.nvim_get_option("lines")

	local win_height = math.ceil(height * 0.8 - 4)
	local win_width = math.ceil(width * 0.8)
	local row = math.ceil((height - win_height) / 2 - 1)
	local col = math.ceil((width - win_width) / 2)

	local border_opts = {
		style = "minimal",
		relative = "editor",
		width = win_width + 2,
		height = win_height + 2,
		row = row - 1,
		col = col - 1,
	}

	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = win_height,
		row = row,
		col = col,
	}

	local border_lines = { "╔" .. string.rep("═", win_width) .. "╗" }
	local middle_line = "║" .. string.rep(" ", win_width) .. "║"
	for i = 1, win_height do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, "╚" .. string.rep("═", win_width) .. "╝")
	api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)

	local border_win = api.nvim_open_win(border_buf, true, border_opts)
	win = api.nvim_open_win(buf, true, opts)
	api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)

	api.nvim_win_set_option(win, "cursorline", true) -- it highlight line with the cursor on it

	-- we can add title already here, because first line will never change
	api.nvim_buf_set_lines(buf, 0, -1, false, { window.center("What have i done?"), "", "" })
	api.nvim_buf_add_highlight(buf, -1, "WhidHeader", 0, 0, -1)
end

function window.printTable(content, outtable, prefix)
	for k, v in pairs(outtable) do
		if type(v) == "string" then
			table.insert(content, prefix .. k .. " -> " .. v)
		else
			if type(v) == "table" then
				table.insert(content, k .. " table")
				window.printTable(content, v, prefix .. "  ")
			end
		end
	end
end

function window.update_view()
	local lineNumber = 1
	local bufferNumber = vim.fn.bufnr("%")
	-- local bufferNumber = 11
	local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
	--
	local viewContentStr = ""
	local viewContent = {}
	if line == "---" then
		viewContent[lineNumber] = line
		yamlHeaderStr = line
		local endOfYaml = false
		while not endOfYaml do
			lineNumber = lineNumber + 1
			line = vim.fn.getbufoneline(bufferNumber, lineNumber)
			viewContent[lineNumber] = line
			yamlHeaderStr = yamlHeaderStr .. "\n" .. line
			if line == "---" then
				endOfYaml = true
			end
		end
	end
end

return window
