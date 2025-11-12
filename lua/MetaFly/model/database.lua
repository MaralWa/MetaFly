local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")
local strftime = sqlite.lib.strftime
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

---@class MetadataToNote
database.MetadataToNote = tbl("MetaDataToNote", {
	id = true,
	idMetaData = { "integer", reference = "MetaData.id", required = true },
	idNote = { "integer", reference = "Note.id", required = true },
	value = { "text" },
})

local function new()
	local self = setmetatable({}, database)
	self.uri = ""
	self.command = ""
	self.NoteBox = database.NoteBox
	self.Note = database.Note
	self.Metadata = database.Metadata
	self.MetadataToNote = database.MetadataToNote
	self.DB = nil
	return self
end

function database:getInstance()
	if not instance then
		instance = new()
	end
	return instance
end

---@class Database
function database:init(config)
	if config.uri then
		self.uri = config.uri
		self.command = "sqlite3 " .. config.uri
	end
	self.DB = sqlite({
		uri = self.uri,
		noteBox = self.NoteBox,
		note = self.Note,
		metaData = self.Metadata,
		metadataToNote = self.MetadataToNote,
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
	local sqlResult = io.popen(command .. ' "' .. statement .. '"')

	return sqlResult
end

---comment
---@param statement string
function database:select(statement)
	return self.DB:eval(statement)
end

return database
