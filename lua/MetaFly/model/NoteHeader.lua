local database = require("MetaFly.model.database")

local logger = require("MetaFly.config"):getInstance():getLogger("NoteHeader")

---@class NoteHeader
---@field private id number
---@field  idNote number
---@field  json string
NoteHeader = {
	id = 0,
	idNote = 0,
	json = "",
}

function NoteHeader:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idNote = row["idNote"]
	newObject.json = row["json"]
	return newObject
end

---@return number
function NoteHeader:getId()
	return self.id
end

---@param aIdNote number
---@return NoteHeader
function NoteHeader.get(aIdNote)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	local row = { idNote = aIdNote }
	local entries = sqlite.MetadataToNote:get({ where = row })
	if #entries == 1 then
		for _, entry in pairs(entries) do
			return NoteHeader:new(entry)
		end
	end
	return NoteHeader:new({ id = -1, idNote = aIdNote })
end

---@param json string
function NoteHeader:update(json)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	if self.id == -1 then
		local rowId = sqlite.MetadataToNote:insert({
			idNote = self.idNote,
			json = json,
		})
	else
		database.MetadataToNote:update({
			where = { id = self.id },
			set = { json = json },
		})
	end
end

return NoteHeader
