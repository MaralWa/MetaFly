local lyaml = require("lyaml")
local api = vim.api
local buf, win

local function center(str)
	local width = api.nvim_win_get_width(0)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

local function open_window()
	buf = api.nvim_create_buf(false, true)
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
	api.nvim_buf_set_lines(buf, 0, -1, false, { center("What have i done?"), "", "" })
	api.nvim_buf_add_highlight(buf, -1, "WhidHeader", 0, 0, -1)
end

local function update_view()
	local lineNumber = 1
	--local bufferNumber = vim.fn.bufnr("%")
	local bufferNumber = 11
	local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
	--
	local yamlHeaderStr = ""
	local yamlHeader = {}
	if line == "---" then
		yamlHeader[lineNumber] = line
		yamlHeaderStr = line
		local endOfYaml = false
		while not endOfYaml do
			lineNumber = lineNumber + 1
			line = vim.fn.getbufoneline(bufferNumber, lineNumber)
			yamlHeader[lineNumber] = line
			yamlHeaderStr = yamlHeaderStr .. "\n" .. line
			if line == "---" then
				endOfYaml = true
			end
		end
	end

	-- yamlHeader[lineNumber] = yamlHeaderStr
	local yamlData = lyaml.load(yamlHeaderStr)
	for k, v in pairs(yamlData) do
		lineNumber = lineNumber + 1
		if type(v) == "string" then
			yamlHeader[lineNumber] = k .. " -> " .. v -- tostring(yamlData[k]) .. " - " .. table.maxn(yamlData[k])
		end
		if type(v) == "table" then
			yamlHeader[lineNumber] = k .. " -> table.len " .. table.maxn(v)
		end
	end
	--	local currentBuffer = api.nvim_win_get_buf(0)
	--	yamlHeader[1] = "Hallo, Welt!"
	--	yamlHeader[2] = "Buffernummer: " .. currentBuffer
	--	--yamlHeader[2] = vim.fn.getbufline(bufferNumber, 2)
	--	-- yamlHeader[3] = api.nvim_buf_get_lines(currentBuffer, 2, 2, false)[0]
	--	local bufName = api.nvim_buf_get_name(currentBuffer)
	--	yamlHeader[3] = vim.fn.getbufoneline(currentBuffer, 2)
	--	yamlHeader[4] = bufName
	api.nvim_buf_set_lines(buf, 0, -1, false, yamlHeader)
end

open_window()
update_view()
-- echo yamlHeader
