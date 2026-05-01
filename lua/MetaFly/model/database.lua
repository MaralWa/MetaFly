local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")
local datetime = sqlite.lib.datetime

local database = {}

database.__index = database

local instance = nil

---@class NoteBoxTable
database.NoteBox = tbl("NoteBox", {
	id = true,
	name = { "text", required = true },
	path = { "text", required = true, unique = true },
	lastUpdated = { "text", default = datetime("now"), required = true },
})

---@class NoteTable
database.Note = tbl("Note", {
	id = true,
	noteId = { "text", required = true },
	title = { "text", required = true },
	type = { "text" },
	context = { "text" },
	status = { "text" },
	tags = { "text" },
	fileName = { "text", required = true },
	idNoteBox = { "integer", reference = "NoteBox.id" },
	created = { "text", default = datetime("now"), required = true },
	lastUpdated = { "text", default = datetime("now"), required = true },
})

---@class Metadata
database.Metadata = tbl("MetaData", {
	id = true,
	name = { "text", required = true, unique = true },
	type = { "text" },
})

---@class MetaDataToNote
database.MetaDataToNote = tbl("MetaDataToNote", {
	id = true,
	idMetaData = { "integer", reference = "MetaData.id", required = true },
	idNote = { "integer", reference = "Note.id", required = true },
	position = { "integer", required = true },
	value = { "text" },
})

---@class JsonDataToNote
database.JsonDataToNote = tbl("JsonDataToNote", {
	id = true,
	idMetaData = { "integer", reference = "MetaData.id", required = true },
	idNote = { "integer", reference = "Note.id", required = true },
	json = { "text" },
})

local function new()
	local self = setmetatable({}, database)
	self.uri = ""
	self.command = ""
	self.NoteBox = database.NoteBox
	self.Note = database.Note
	self.Metadata = database.Metadata
	self.MetaDataToNote = database.MetaDataToNote
	self.JsonDataToNote = database.JsonDataToNote
	self.DB = nil
	return self
end

function database:getInstance()
	if not instance then
		instance = new()
		instance:init()
	end
	return instance
end

---@class Database
function database:init()
	local config = require("MetaFly.config"):getInstance()
	if config.database then
		self.uri = config.database
		self.command = "sqlite3 " .. config.database
	end
	self.DB = sqlite:extend({
		uri = self.uri,
		NoteBox = self.NoteBox,
		Note = self.Note,
		Metadata = self.Metadata,
		MetaDataToNote = self.MetaDataToNote,
		JsonDataToNote = self.JsonDataToNote,
		opt = {},
	})
end

---@param uri string
function database:setUri(uri)
	self.uri = uri
end

---@return string
function database:getUri()
	return self.uri
end

---@param command string
function database:setCommand(command)
	self.command = command
end

---@return string
function database:getCommand()
	return self.command
end

function database:getSqlite()
	return self.DB
end

---@param values table
---@return number
function database:insertNote(values)
	return self.DB.Note.insert(values)
end

function database:callSql(statement, mode)
	local command = self.command
	if mode ~= nil then
		command = command .. " -" .. mode
	end
	print("Executing command: " .. command .. ' "' .. statement .. '"')
	local sqlResult = io.popen(command .. ' "' .. statement .. '"')

	return sqlResult
end

function database:executeQuery(statement, mode)
	local sqlResult = self:callSql(statement, mode)
	local lines = {}

	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			table.insert(lines, line)
		end
		sqlResult:close()
	else
		lines = { "No results returned" }
	end
	return lines
end

function database:executeQuery(statement, mode)
	local sqlResult = self:callSql(statement, mode)
	local lines = {}

	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			table.insert(lines, line)
		end
		sqlResult:close()
	else
		lines = { "No results returned" }
	end

	return lines
end

function database:getQueryResultAsTable(statement)
	local resultLines = self:executeQuery(statement, "json")
	local jsonResult = table.concat(resultLines, "")

	local ok, data = pcall(vim.json.decode, jsonResult)
	if not ok then
		print("Error decoding JSON: " .. data)
		return nil
	end

	return data
end

function database:getPropertyOfCurrentBuffer(property)
	local fileName = vim.api.nvim_buf_get_name(0)
	local statement = "select "
		.. property
		.. " as property, "
		.. "NoteBox.path || '/' || Note.fileName as fullFileName "
		.. "from Note, NoteBox where Note.idNoteBox = NoteBox.id and "
		.. "fullFileName = '"
		.. fileName
		.. "'"
	print("Executing SQL: " .. statement)

	local sqlResult = self:callSql(statement, "json")
	local jsonResult = ""

	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			jsonResult = jsonResult .. line
		end
		sqlResult:close()
	end
	print("SQL Result: " .. jsonResult)

	if jsonResult == nil or jsonResult == "" then
		return nil
	end

	local ok, data = pcall(vim.json.decode, jsonResult)
	if not ok then
		print("Error decoding JSON: " .. data)
		return nil
	end
	if #data == 1 then
		return data[1].property
	end
end

---comment
---@param statement string
function database:select(statement)
	return self.DB:eval(statement)
end

return database
