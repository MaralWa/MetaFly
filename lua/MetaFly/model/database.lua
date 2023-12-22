local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")

local julianday, strftime = sqlite.lib.julianday, sqlite.lib.strftime

local database = {
	uri = "",
}

--[[

---@class NoteBox
---@field id number: unique id
---@field name string: name of the NoteBox
---@field path string: full path of the NoteBox
---@field lastUpdated: date and tim of last updae

---@class Note
---@field id number: unique id
---@field noteId string: id in NoteBox
---@field title string: title of the Note
---@field type string: type of the Note
---@field context string: status of the Note
---@field status string: status of the Note
---@field taqs string: tags of of the Note
---@field fileName string: file name of the Note
---@field idNoteBox number: id of the NoteBox in which the Note is stored
---@field created: date and time when the note was created
---@field lastUpdated: date and time when the row was updated

---@class Metadata
---@field id number: unique id
---@field name string: name of the metadata
---@field type string: type of the metadata

--]]

--[[ sqlite classes ------------------------------------------

---@class MetadataToNote
---@field idMetadata number: id of the metadata
---@field idNote number: id of the note
---@field value string: vulue of the metadata

---@class NoteBoxTable: sqlite_tbl
---@class NoteTable: sqlite_tbl
---@class Metadata: sqlite_tbl
---@class MetadataToNote: sqlite_tbl

---@class Database: sqlite_db
---@field noteBox NoteBoxTable
---@field note NoteTable
---@field metadata Metadata
---@field metadataToNote MetadataToNote

--]]

---@class NoteBoxTable
database.NoteBox = tbl("NoteBox", {
	id = true,
	name = { "text", required = true },
	path = { "text", required = true, unique = true },
	lastUpdated = { "date", default = strftime("%s", "now"), required = true },
})

---@class NoteTable
database.Note = tbl("Note", {
	id = true,
	noteId = { "text", required = true, unique = true },
	title = { "text", required = true },
	type = { "text" },
	context = { "text" },
	status = { "text" },
	taqs = { "text" },
	fileName = { "text", required = true, unique = true },
	idNoteBox = { reference = "NoteBox.id" },
	created = { "date", default = strftime("%s", "now"), required = true },
	lastUpdated = { "date", default = strftime("%s", "now"), required = true },
})

---@class Metadata
database.Metadata = tbl("MetaData", {
	id = true,
	name = { "text", required = true, unique = true },
	type = { "text" },
})

---@class MetadataToNote
database.MetadataToNote = tbl("MetadataToNote", {
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

return database
