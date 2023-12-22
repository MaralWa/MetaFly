require("MetaFly.model.YamlHeader")

local database = require("MetaFly.model.database")

---@class Note
---@field private id number
---@field private idNoteBox number
---@field private noteId string
---@field public title string
---@field public type string
---@field public context string
---@field public status string
---@field public fileName string
---@field public created number
---@field public lastUpdated number
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
	created = 0,
	lastUpdated = 0,
	tags = "",
}

---@param id number
---@param values table
---@return Note
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
	newObject.tags = values["tags"]
	return newObject
end

---@return number
function Note:getId()
	return self.id
end

---@return number
function Note:getIdNoteBox()
	return self.idNoteBox
end

---@param idNoteBox number
---@param noteId string
---@return Note
function Note.getNoteWithId(idNoteBox, noteId)
	local row = {}
	row["idNoteBox"] = idNoteBox
	row["noteId"] = noteId
	local selectedRows = database.Note:get(row)
	if #selectedRows == 1 then
		for rowId, values in pairs(selectedRows) do
			return Note:new(rowId, values)
		end
	end
	return Note:new(-1, row)
end

---@param values table
function Note:upate(values)
	values["lastUpdated"] = os.time()
	if self.id == -1 then
		self.id = database.Note:insert(values)
	else
		database.Note:update({
			where = { id = self.id },
			set = values,
		})
	end
	self.title = values["title"]
	self.type = values["type"]
	self.context = values["context"]
	self.status = values["status"]
	self.fileName = values["fileName"]
	self.created = values["created"]
	self.lastUpdated = values["lastUpdated"]
	self.tags = values["tags"]
end

return Note
