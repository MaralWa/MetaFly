local lyaml = require("lyaml")

local NoteData = {
	title = true,
	type = true,
	context = true,
	status = true,
}

---@class YamlHeader
---@field private fileName string
---@field private bufferNumber number
---@field private headerLines table
---@field private headerData table
---@field private warnings table
---@field private noteData table
---@field private metaData table
---@field private mapping table of mapping functions
local YamlHeader = {
	fileName = "",
	bufferNumber = -1,
	header = {},
	headerLines = {},
	warnings = {},
	mapping = {},
	noteData = {},
	metaData = {}
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
	newObject.noteData = {}
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

function YamlHeader:parseDocument()
	self.header = lyaml.load(table.concat(self.headerLines, "\n"))
	for key, value in pairs(self.header) do
		if NoteData[key] then
			self.noteData[key] = value
		else
			self.metaData[key] = value
		end
	end
	self.noteData["noteId"] = self.header["id"]
	self.metaData["id"] = nil
	self.noteData["tags"] = type(self.header["tags"]) == "table" and table.concat(self.header["tags"], ", ")
		or noteData["tags"]
	self.metaData["tags"] = nil
	self.noteData["created"] = os.time({
		year = string.sub(self.header["date"], 7, 10),
		month = string.sub(self.header["date"], 4, 5),
		day = string.sub(self.header["date"], 1, 2),
		hour = string.sub(self.header["date"], 12, 13),
		min = string.sub(self.header["date"], 15, 16),
		sec = 0,
	})
	self.metaData["date"] = nil
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
	yamlHeader:parseDocument()
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
	yamlHeader:parseDocument()
	return yamlHeader
end

return YamlHeader
