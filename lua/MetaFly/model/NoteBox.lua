local database = require("MetaFly.model.database")

---@class NoteBox
---@field private id number
---@field private path string
---@field private name string
local NoteBox = {
	id = 0,
	path = "",
	name = "",
}

---@param id number
---@param values table
function NoteBox:new(id, values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.id = id
	newObject.name = values["name"]
	newObject.path = values["path"]
	return newObject
end

---@return string name of the notebox
function NoteBox:getName()
	return self.name
end

---@return string path of the notebox
function NoteBox:getPath()
	return self.path
end

---@param values table
function NoteBox:upadate(values)
	database.NoteBox:update({ values, id = self.id })
end

--- Intert an entry in table NoteBox
---@param row table
---@return NoteBox|{ [unknown]: any }
function NoteBox.insert(row)
	local id = database.NoteBox:insert(row)
	return NoteBox:new(id, row)
end

---@param  aRow table
---@return NoteBox
---@return nil
function NoteBox.select(aRow)
	local selectedNoteBox = database.NoteBox:get({
		where = aRow,
	})
	if #selectedNoteBox == 1 then
		for rowId, row in pairs(selectedNoteBox) do
			return NoteBox:new(rowId, row)
		end
	end
	return NoteBox:new(-1, {})
end

--- return the NoteBox with the given id
---@param id number
function NoteBox.getById(id)
	selectedNoteBox = database.NoteBox.get(id)
	if #selectedNoteBox == 1 then
		for rowId, values in pairs(selectedNoteBox) do
			return NoteBox:new(rowId, values)
		end
	end
	return nil
end

---comment
---@param row table
---@return NoteBox
function NoteBox.selectOrInsertNoteBox(row)
	local noteBox = NoteBox.select(row)
	if noteBox.id > 0 then
		return noteBox
	else
		return NoteBox.insert(row)
	end
end

--- Inserts an new note with the given noteId in the NoteBox
---comment
---@param noteId string noteId of the the Note
---@return Note
function NoteBox:insertNote(noteId)
	local values = {}
	values["noteId"] = noteId
	values["idNoteBox"] = self.id
	local rowId = database.Note.insert(values)
	return Note:new(rowId, values)
end

---@param noteId string
---@return Note
function NoteBox:getNoteWithId(noteId)
	local row = {}
	row["idNoteBox"] = self.id
	row["noteId"] = noteId
	local selectedRows = database.Note.get(row)
	if #selectedRows == 1 then
		for rowId, values in pairs(selectedRows) do
			return Note:new(rowId, values)
		end
	end
	return Note:new(-1, {})
end

return NoteBox
