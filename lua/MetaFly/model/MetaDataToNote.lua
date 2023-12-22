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

function MetaDataToNote:new(id, row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = id
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.value = row["value"]
	return newObject
end

---@return number
function MetaDataToNote:getId()
	return self.id
end

---@param idMetaData number
---@param idNote number
---@return MetaDataToNote
function MetaDataToNote:get(idMetaData, idNote)
	local entry = database.MetadataToNote:get({ idMetaData = idMetaData, idNote = idNote })
	if #entry == 1 then
		for rowId, row in pairs(entry) do
			return MetaDataToNote:new(rowId, row)
		end
	end
	return MetaDataToNote:new(-1, { idMetaData = idMetaData, idNote = idNote })
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
