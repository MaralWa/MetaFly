local database = require("MetaFly.model.database")
local NoteBox = require("MetaFly.model.NoteBox")

---@class Note
---@field private id number
---@field private idNoteBox number
---@field private noteId string
---@field public title string
---@field public type string
---@field public context string
---@field public status string
---@field public fileName string
---@field public created string
---@field public lastUpdated string
---@field public tags string
local Note = {
	id = 0,
	idNoteBox = 0,
	noteId = "",
	title = "",
	type = "",
	context = "",
	status = "",
	fileName = "",
	created = "",
	lastUpdated = "",
	tags = "",
}

---@param id number
---@param values table
function Note:new(id, values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.id = id
	newObject.idNoteBox = values["idNoteBox"]
	newObject.noteId = values["noteId"]
	newObject.title = values["title"]
	newObject.type = values["type"]
	newObject.context = values["context"]
	newObject.status = values["status"]
	newObject.fileName = values["fileName"]
	newObject.created = values["created"]
	newObject.lastUpdated = values["lastUpdated"]
	newObject.taqs = values["tags"]
	return newObject
end

---@return NoteBox | nil
function Note:getNoteBox()
	return NoteBox.getById(self.idNoteBox)
end

function Note:upate() end

return Note
