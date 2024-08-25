local lyaml = require("lyaml")
local NoteBox = require("MetaFly.model.NoteBox")

local NoteData = {
	title = "title",
	type = "type",
	context = "context",
	status = "status",
	id = "noteId",
}

---@class YamlHeader
---@field private fileName string
---@field private bufferNumber number
---@field private headerLines table
---@field private headerData table
---@field private warnings table
---@field private noteData table
---@field private metaData table
---@field private mappings table of mapping functions
local YamlHeader = {
	fileName = "",
	bufferNumber = -1,
	header = {},
	headerLines = {},
	warnings = {},
	mapping = {},
	noteData = {
		idNoteBox = "",
		noteId = "xxxx",
		type = "note",
		status = "",
		context = "",
		created = os.time(),
	},
	metaData = {},
}

---@return YamlHeader
---@param fileName string
---@param bufferNumber number
function YamlHeader:new(fileName, bufferNumber)
	local newObject = setmetatable({}, self)
	self.__index = self
	newObject.fileName = fileName
	newObject.bufferNumber = bufferNumber
	newObject.header = {}
	newObject.headerLines = {}
	newObject.warnings = {}
	newObject.mappings = {}
	newObject.noteData = {
		idNoteBox = "",
		type = "note",
		status = "",
		context = "",
		created = os.time(),
	}
	newObject.metaData = {}
	return newObject
end

---@param headerLines table
function YamlHeader:setHeaderLines(headerLines)
	self.headerLines = headerLines
end

---@return table
function YamlHeader:getHeaderLines()
	return self.headerLines
end

---@return table
function YamlHeader:getHeader()
	return self.header
end

---@return string
function YamlHeader:getFileName()
	return self.fileName
end

---@param key string
---@param default string
function YamlHeader:getValue(key, default)
	if self.header[key] ~= nil then
		return self.header[key]
	end
	return default
end

---@return string | nil
function YamlHeader:getTitle()
	-- use Titel as title if pesent
	if self.header.Titel ~= nil and type(self.header.Titel) ~= "table" then
		return self.header.Titel
	end
	-- use first alias as title if any aliases are defined
	if self.header.aliases ~= nil and type(self.header.aliases) == "table" then
		for key, value in pairs(self.header.aliases) do
			if type(value) ~= "table" then
				return value
			end
		end
	end
	--
	return nil
end

---@param noteBox NoteBox
function YamlHeader:parseDocument(noteBox)
	self.header = lyaml.load(table.concat(self.headerLines, "\n"))
	for key, value in pairs(self.header) do
		if NoteData[key] ~= nil then
			self.noteData[NoteData[key]] = type(value) ~= "table" and "" .. value or table.concat(value, ", ")
		else
			self.metaData[key] = value
		end
	end
	if self.noteData.title == nil or self.noteData.title == "" then
		self.noteData.title = self.getTitle(self)
	end
	self.noteData.idNoteBox = "" .. noteBox:getId()
	self.noteData.fileName = noteBox:getRelativePath(self.fileName)
	if self.header.id ~= nil and type(self.header.id) ~= "table" then
		self.noteData.noteId = "" .. self.header.id
	end
	if self.noteData.noteId == nil and self.noteData.title ~= nil then
		self.noteData.noteId = self.noteData.title
	end
	--self.metaData.id = nil
	if self.header.tags ~= nil then
		if type(self.header.tags) == "table" then
			self.noteData.tags = #self.header["tags"] > 0 and table.concat(self.header["tags"], ", ") or ""
		else
			self.noteData.tags = self.noteData["tags"]
		end
		self.metaData.tags = nil
	end
	if self.header.date ~= nil then
		self.noteData.created = ""
			.. os.time({
				year = string.sub(self.header["date"], 7, 10),
				month = string.sub(self.header["date"], 4, 5),
				day = string.sub(self.header["date"], 1, 2),
				hour = string.sub(self.header["date"], 12, 13),
				min = string.sub(self.header["date"], 15, 16),
				sec = 0,
			})
		self.metaData["date"] = nil
	else
		self.noteData.created = "" .. os.time()
	end
end

---@return table
function YamlHeader:getNoteData()
	return self.noteData
end

---@return table
function YamlHeader:getMetaData()
	return self.metaData
end

---@param bufferNumber number
---@return YamlHeader, string | nil
function YamlHeader:getFromBuffer(bufferNumber)
	local yamlHeader = YamlHeader:new(vim.fn.bufname(bufferNumber), bufferNumber)

	local lineNumber = 1
	local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
	if line ~= "---" then
		return yamlHeader, "buffer " .. bufferNumber .. " does not start with yaml header"
	end
	local headerLines = { line }
	repeat
		local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
		table.insert(headerLines, line)
		lineNumber = lineNumber + 1
	until line == "---"
	yamlHeader:setHeaderLines(headerLines)
	return yamlHeader
end

---@param fileName string
---@return YamlHeader, string | nil
function YamlHeader:getFromFile(fileName)
	local yamlHeader = YamlHeader:new(fileName, -1)
	local file = io.open(fileName)
	if file == nil then
		return yamlHeader, "Could not open file " .. fileName
	end
	local headerLines = {}
	for line in file:lines() do
		if #headerLines == 0 and line ~= "---" then
			return yamlHeader, "file " .. fileName .. " does not start with yaml header"
		end
		table.insert(headerLines, line)
		if #headerLines > 1 and line == "---" then
			break
		end
	end
	yamlHeader:setHeaderLines(headerLines)
	return yamlHeader
end

return YamlHeader
