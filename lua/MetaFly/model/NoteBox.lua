local database = require("MetaFly.model.database")

---@class NoteBox
---@field private id number
---@field private path string
---@field private name string
---@field private lastUpdated number
local NoteBox = {
	id = 0,
	path = "",
	name = "",
	lastUpdated = 0,
}

---@param id number
---@param values table
function NoteBox:new(id, values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.id = id
	newObject.name = values["name"]
	newObject.path = string.sub(values["path"], -1, -1) ~= "/" and values["path"] or string.sub(values["path"], 1, -2)
	--	newObject.lastUpdated = values["lastUpdated"]
	return newObject
end

---@return number
function NoteBox:getId()
	return self.id
end

---@return string name of the notebox
function NoteBox:getName()
	return self.name
end

---@return string path of the notebox
function NoteBox:getPath()
	return self.path
end

---@return number date and time of last upadate as UNIX
--timestamp
function NoteBox:getLastUpdated()
	return self.lastUpdated
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
	return NoteBox:new(-1, aRow)
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

---@return integer number of notes in the note box
function NoteBox:getNumberOfNotes()
	return database.Note:count({ idNoteBox = self.id })
end

---
---@return table
function NoteBox:scanForNotes()
	local findCommand = "find " .. self.path .. ' -name "*.md" -type f -depth 1'
	if 0 < self:getNumberOfNotes() then
		findCommand = findCommand .. '-newermt "' .. os.date("%Y-%m-%d %H:%M", self.lastUpdated) .. '"'
	end
	local fileList = {}
	local p = io.popen(findCommand) --Open directory look for files, save data in p. By giving '-type f' as parameter, it returns all files.
	if p ~= nil then
		for file in p:lines() do
			table.insert(fileList, file)
		end
	end
	return fileList
end

function NoteBox:getRelativePath(fileName)
	return string.gsub(fileName, self.path .. "/", "")
end

return NoteBox
