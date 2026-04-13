require("MetaFly.model.YamlHeader")

local logger = require("MetaFly.config"):getInstance():getLogger("Note")

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

---@param values table
---@return Note
function Note:new(values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.id = values["id"]
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

---@return string
function Note:getNoteId()
	return self.noteId
end

---@param pWhere  table
---@return integer
function Note.count(pWhere)
	local selectedRows = database.Note:get({ where = pWhere })
	return #selectedRows
end

---@param idNoteBox number
---@param noteId string
---@return Note
function Note.getNoteWithId(idNoteBox, noteId)
	local row = {}
	row["idNoteBox"] = idNoteBox
	row["noteId"] = noteId
	local selectedRows = database.Note:get({ where = row })
	if #selectedRows == 1 then
		for _, values in pairs(selectedRows) do
			return Note:new(values)
		end
	end
	row.id = -1
	local newNote = Note:new(row)
	return newNote
end

---@param values table
---@return Note | nil
function Note.saveValues(values)
	logger.debug("Saving note data: " .. vim.inspect(values))
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	if not sqlite then
		logger:debug("Failed to get sqlite instance")
		return nil
	end
	local row = { idNoteBox = values["idNoteBox"], noteId = values["noteId"] }
	local selectedRow = sqlite.Note:get({
		where = row,
	})
	local idNote = nil
	if #selectedRow == 0 then
		idNote = sqlite.Note:insert(values)

		values.id = idNote
		return Note:new(values)
	elseif #selectedRow == 1 then
		for _, rowValues in pairs(selectedRow) do
			sqlite.Note:update({
				where = { id = rowValues.id },
				set = values,
			})
			values.id = rowValues.id
			return Note:new(values)
		end
	else
		return nil
	end
end

---@param values table
function Note:upate(values)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	values["lastUpdated"] = os.time()
	if self.id == -1 then
		self.id = sqlite.Note:insert(values)
	else
		sqlite.Note:update({
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
