local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local MetaFly = {}

--[[
---@class MetaFly.Zettelkasten
---@field id number: unique id
---@field name string: name of the Zettelkasten
---@field path string: full path of the Zettelkasten

---@class MetaFly.Zettel
---@field id number: unique id
---@field idTag string: id in Zettelkasten
---@field title string: title of the Zettel
---@field type string: type of the Zettel
---@field status string: status of the Zettel
---@field taqs string: tags of of the Zettel
---@field fileName string: file name of the Zettel
---@field idZettlekasen number: id of the Zettelkasten in which the Zettel is stored

---@class MetaFly.ZettelkastenTable: sqlite_tbl
---@class MetaFly.ZettelTable: sqlite_tbl

---@class MetaFly.Database: sqlite_db
---@field zettelkasten MetaFly.ZettelkastenTable
---@field zettel MetaFly.ZettelTable

--]]

---@type MetaFly.ZettelkastenTable
MetaFly.Zettelkasten = tbl("Zettelkasten", {
	id = true,
	name = { "text", required = true },
	path = { "text", required = true },
})

---@type MetaFly.ZettelTable
MetaFly.Zettel = tbl("Zettel", {
	id = true,
	idTag = { "text", required = true },
	title = { "text", required = true },
	type = { "text" },
	status = { "text" },
	taqs = { "text" },
	fileName = { "text", required = true },
	idZettlekasen = { reference = "Zettelkasten.id" },
})

---@type MetaFly.Database
MetaFly.database = sqlite({
	uri = "/Users/sarah/Documents/vimwiki/MetaFly/metadata.db",
	zettelkasten = MetaFly.Zettelkasten,
	zettel = MetaFly.Zettel,
	opt = {},
})

local zettelkasten = MetaFly.Zettelkasten

---@param path string
---@return MetaFly.Zettelkasten
function zettelkasten:get(path)
	return MetaFly:getZettelkastenId()
end

function MetaFly:getZettelkastenIdTmp(strPath)
	local selectedZettlekasten = MetaFly.Zettelkasten:__get({
		select = { "path", "name" },
		where = { path = strPath },
	})
	local lines = {}
	local zettlekasten = {}
	colId = "rowId"
	zettlekasten[colId] = 0
	idValue = 0
	if #selectedZettlekasten == 1 then
		MetaFly.printTable(lines, selectedZettlekasten, "selected: ")
		for rowIdi, row in pairs(selectedZettlekasten) do
			return rowIdi, row
			--      zettlekasten[colId] = "" .. rowIdi
			--      idValue = idValue
			--      for k, v in pairs(row) do
			--        zettlekasten[k] = v
			--      end
		end
	end
end

function MetaFly:getZettelkastenId(strPath)
	MetaFly.open_window()
	local key, values = MetaFly.getZettelkastenIdTmp(self, strPath)
	local test = {}
	local lines = {}
	table.insert(lines, "key: " .. key)
	table.insert(lines, "")
	MetaFly.printTable(lines, values, "... ")
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function MetaFly.initialize()
	local idZettelkasten = MetaFly.Zettelkasten.insert(MetaFly.Zettelkasten, {
		name = "VimWiki",
		path = "/Users/sarah/Documents/vimwiki",
	})
	return idZettelkasten
end

function MetaFly.center(str)
	local width = api.nvim_win_get_width(0)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

function MetaFly.open_window()
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
	api.nvim_buf_set_lines(buf, 0, -1, false, { MetaFly.center("What have i done?"), "", "" })
	api.nvim_buf_add_highlight(buf, -1, "WhidHeader", 0, 0, -1)
end

function MetaFly.printTable(content, outtable, prefix)
	for k, v in pairs(outtable) do
		if type(v) == "string" then
			table.insert(content, prefix .. k .. " -> " .. v)
		else
			if type(v) == "table" then
				table.insert(content, k .. " table")
				MetaFly.printTable(content, v, prefix .. "  ")
			end
		end
	end
end

function MetaFly.update_view()
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

	-- viewContent[lineNumber] = viewContentStr
	local yamlData = lyaml.load(yamlHeaderStr)
	--	for k, v in pairs(yamlData) do
	--		if type(v) == "string" then
	--			table.insert(viewContent, k .. " - " .. v)
	--		end
	--		if type(v) == "table" then
	--			table.insert(viewContent, k .. " -> table.len " .. table.maxn(v))
	--		end
	--	end
	--	local currentBuffer = api.nvim_win_get_buf(0)
	--	viewContent[1] = "Hallo, Welt!"
	--	viewContent[2] = "Buffernummer: " .. currentBuffer
	--	--viewContent[2] = vim.fn.getbufline(bufferNumber, 2)
	--	-- viewContent[3] = api.nvim_buf_get_lines(currentBuffer, 2, 2, false)[0]
	--	local bufName = api.nvim_buf_get_name(currentBuffer)
	--	viewContent[3] = vim.fn.getbufoneline(currentBuffer, 2)
	--	viewContent[4] = bufName

	--       local db2 = sqlite.open("/Users/sarah/Documents/vimwiki/MetaFly/metadata.db")
	local entries = sqlite.with_open("/Users/sarah/Documents/vimwiki/MetaFly/metadata.db", function(db)
		-- return db:select("slipBox")
		MetaFly.printTable(viewContent, yamlData, "")
		MetaFly.printTable(viewContent, db, "")
		db:insert("note", { id = yamlData["id"], title = yamlData["title"], fileName = "", idSlipBox = "VimWiki" })
		return db:eval("select * from note")
	end)
	table.insert(viewContent, "")
	if type(entries) == "table" then
		table.insert(viewContent, "Anzahl: " .. table.maxn(entries))
	end
	for key, row in pairs(entries) do
		for column, value in pairs(row) do
			table.insert(viewContent, column .. ": " .. value)
		end
	end

	--  table.insert(viewContent, "")
	--  local db2 = sqlite.open("/Users/sarah/Documents/vimwiki/MetaFly/metadata.db")
	--  if db2 ~= nil then
	--    table.insert(viewContent, "neue db:" .. tostring(db2))
	--    table.insert(viewContent, "neue db type:" .. type(db2))
	--    MetaFly.printTable(viewContent, db2, "")
	--    -- db2:open()
	--    -- local rs = db2:eval("select * from slipBox")
	--    -- local rs = db2:select("slipBox")
	--    -- local rs =
	--    -- 	db2:insert("note", { id = yamlData["id"], title = yamlData["title"], fileName = "", idSlipBox = "VimWiki" })
	--    -- table.insert(viewContent, "insert resutl: " .. type(rs))
	--  else
	--    table.insert(viewContent, "keine DB Verbindung")
	--  end
	table.insert(viewContent, "T E S T")
	table.insert(viewContent, "Zettelkasten: " .. MetaFly.initialize())
	MetaFly.open_window()
	-- print(buf)
	api.nvim_buf_set_lines(buf, 0, -1, false, viewContent)
end

return MetaFly
