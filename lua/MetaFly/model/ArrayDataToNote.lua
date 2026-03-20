local database = require("MetaFly.model.database")

local logger = require("MetaFly.utils.Logger")

---@class ArrayDataToNote
---@field private id number
---@field  idMetaData number
---@field  idNote number
---@field  values string
ArrayDataToNote = {
	id = 0,
	idMetaData = 0,
	idNote = 0,
	values = "",
}

function ArrayDataToNote:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.values = row["values"]
	return newObject
end

---@return number
function ArrayDataToNote:getId()
	return self.id
end

---@param aIdMetaData number
---@param aIdNote number
---@return ArrayDataToNote
function ArrayDataToNote.get(aIdMetaData, aIdNote)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	local row = { idMetaData = aIdMetaData, idNote = aIdNote }
	local entries = sqlite.MetadataToNote:get({ where = row })
	if #entries == 1 then
		for _, entry in pairs(entries) do
			return ArrayDataToNote:new(entry)
		end
	end
	return ArrayDataToNote:new({ id = -1, idMetaData = aIdMetaData, idNote = aIdNote })
end

---@param values string
function ArrayDataToNote:update(values)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	if self.id == -1 then
		local rowId = sqlite.MetadataToNote:insert({
			idMetaData = self.idMetaData,
			idNote = self.idNote,
			values = values,
		})
	else
		database.MetadataToNote:update({
			where = { id = self.id },
			set = { values = values },
		})
	end
end

return ArrayDataToNote
