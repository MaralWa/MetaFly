require("MetaFly.model.YamlHeader")
local MetaFlyPopUp = require("MetaFly.view.MetaFlyPopUp")
local TableUtils = require("MetaFly.utils.TableUtils")

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
---@param pPopup MetaFlyPopUp | nil
---@return integer
function Note.count(pWhere, pPopup)
	local selectedRows = database.Note:get({ where = pWhere })
	return #selectedRows
end

---@param idNoteBox number
---@param noteId string
---@param popup MetaFlyPopUp | nil
---@return Note
function Note.getNoteWithId(idNoteBox, noteId, popup)
	local row = {}
	row["idNoteBox"] = idNoteBox
	row["noteId"] = noteId
	local selectedRows = database.Note:get({ where = row })
	if #selectedRows == 1 then
		for _, values in pairs(selectedRows) do
			return Note:new(values)
		end
	end
	if popup ~= nil then
		popup:appendLine("Note.getNoteWithId:")
		popup:appendLines(TableUtils.convertToLines(row))
	end
	row.id = -1
	local newNote = Note:new(row)
	if popup ~= nil then
		popup:appendLine(" - " .. newNote:getId())
		popup:appendLine(" - " .. newNote:getNoteId())
		popup:appendLine(" - " .. newNote:getIdNoteBox())
	end
	return newNote
end

---@param values table
---@param popup MetaFlyPopUp | nil
---@return Note | nil
function Note.saveValues(values, popup)
	local row = { idNoteBox = values["idNoteBox"], noteId = values["noteId"] }
	local selectedRow = database.Note:get({
		where = row,
	})
	if popup ~= nil then
		popup:appendLine("Note.saveValues:")
		popup:appendLines(TableUtils.convertToLines(selectedRow))
	end
	local idNote = nil
	local savedNote = nil
	if #selectedRow == 0 then
		idNote = database.Note:insert(values)
		values.id = idNote
		return Note:new(values)
	elseif #selectedRow == 1 then
		for _, rowValues in pairs(selectedRow) do
			database.Note:update({
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
---@param popup MetaFlyPopUp | nil
function Note:upate(values, popup)
	values["lastUpdated"] = os.time()
	if popup ~= nil then
		popup:appendLine("Note.upate:")
		popup:appendLines(TableUtils.convertToLines(values))
	end
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
