local database = require("MetaFly.model.database")

---@class MetaDataToNote
---@field private id number
---@field  idMetaData number
---@field  idNote number
---@field  value string
MetaDataToNote = {
	id = 0,
	idMetaData = 0,
	idNote = 0,
	value = "",
}

function MetaDataToNote:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.value = row["value"]
	return newObject
end

---@return number
function MetaDataToNote:getId()
	return self.id
end

---@param aIdMetaData number
---@param aIdNote number
---@return MetaDataToNote
function MetaDataToNote.get(aIdMetaData, aIdNote)
	local row = { idMetaData = aIdMetaData, idNote = aIdNote }
	local entries = database.MetadataToNote:get({ where = row })
	if #entries == 1 then
		for _, entry in pairs(entries) do
			return MetaDataToNote:new(entry)
		end
	end
	return MetaDataToNote:new({ id = -1, idMetaData = aIdMetaData, idNote = aIdNote })
end

---@param value string
function MetaDataToNote:update(value)
	if self.id == -1 then
		local rowId = database.MetadataToNote:insert({
			idMetaData = self.idMetaData,
			idNote = self.idNote,
			value = value,
		})
	else
		database.MetadataToNote:update({
			where = { id = self.id },
			set = { value = value },
		})
	end
end

return MetaDataToNote
