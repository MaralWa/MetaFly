local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local strftime = sqlite.lib.strftime
local datetime = sqlite.lib.datetime

local database = {
	uri = "",
}

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

---@class Database
---@field noteBox NoteBox
function database:init(uri)
	database.DB = sqlite({
		uri = uri,
		noteBox = database.NoteBox,
		note = database.Note,
		metaData = database.Metadata,
		metadataToNote = database.MetadataToNote,
		opt = {},
	})
end

---comment
---@param statement string
function database:select(statement)
	return self.DB:eval(statement)
end

return database
