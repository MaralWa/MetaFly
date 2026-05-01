local lyaml = require("lyaml")
local Config = require("MetaFly.config")

local logger = nil

local NoteData = {
	title = "title",
	type = "type",
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
		noteId = "",
		title = "",
		type = "",
		status = "",
		created = os.time(),
	},
	metaData = {},
}

---@return YamlHeader
---@param fileName string
---@param bufferNumber number
function YamlHeader:new(fileName, bufferNumber)
	logger = require("MetaFly.config"):getInstance():getLogger()
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
		type = "",
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
		for _, value in pairs(self.header.aliases) do
			if type(value) ~= "table" then
				return value
			end
		end
	end
	--
	return nil
end

function YamlHeader:createDateFromString(dateStr)
	if nil == dateStr or #dateStr < 16 then
		return os.time()
	end
	local day = tonumber(string.sub(dateStr, 1, 2))
	local month = tonumber(string.sub(dateStr, 4, 5))
	local year = tonumber(string.sub(dateStr, 7, 10))
	local hour = tonumber(string.sub(dateStr, 12, 13))
	local min = tonumber(string.sub(dateStr, 15, 16))
	if day == nil or month == nil or year == nil or hour == nil or min == nil then
		return os.time()
	end
	return os.time({ year = year, month = month, day = day, hour = hour, min = min, sec = 0 })
end

function YamlHeader:safe_load_with_logger(yaml_str)
	local ok, result_or_err = xpcall(function()
		return lyaml.load(yaml_str)
	end, function(err)
		return debug.traceback(err, 2)
	end)

	if not ok then
		local msg = "YAML parse error for file " .. self.fileName .. ": " .. result_or_err
		logger.error(msg)
		return nil, result_or_err
	end

	return result_or_err, nil
end

function YamlHeader:parseYaml(yaml_text)
	return self:safe_load_with_logger(yaml_text)
end

function YamlHeader:asJson(value)
	if value == nil then
		return nil
	end
	if type(value) == "string" and value ~= "" then
		return vim.fn.json_encode({ value })
	end
	if type(value) == "table" and #value > 0 then
		return vim.fn.json_encode(value)
	end
	return nil
end

function YamlHeader:parseDocument()
	if self.headerLines == nil then
		return nil
	end
	self.header, error = self:parseYaml(table.concat(self.headerLines, "\n"))
	if not self.header then
		logger.error("Failed to parse YAML header in file " .. self.fileName .. ": " .. error)
		return nil
	end
	if type(self.header) ~= "table" then
		logger.error("YAML header in file " .. self.fileName .. " is not a table")
		return nil
	end
	for key, value in pairs(self.header) do
		if NoteData[key] ~= nil then
			self.noteData[NoteData[key]] = type(value) ~= "table" and "" .. value or table.concat(value, ", ")
		else
			self.metaData[key] = value
		end
	end
	if self.noteData.title == nil or self.noteData.title == "" then
		self.noteData.title = self:getTitle()
	end
	if self.header.id ~= nil and type(self.header.id) ~= "table" then
		self.noteData.noteId = "" .. self.header.id
	end
	if self.noteData.noteId == nil and self.noteData.title ~= nil then
		self.noteData.noteId = self.noteData.title
	end
	--self.metaData.id = nil
	self.noteData.tags = self:asJson(self.header.tags)
	self.metaData.tags = nil
	self.noteData.context = self:asJson(self.header.context)
	self.metaData.context = nil
	self.noteData.created = "" .. self:createDateFromString(self.header["date"])
	return self.noteData
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
		line = vim.fn.getbufoneline(bufferNumber, lineNumber)
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
