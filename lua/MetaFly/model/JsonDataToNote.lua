local database = require("MetaFly.model.database")

local logger = require("MetaFly.config"):getInstance():getLogger("JsonDataToNote")

---@class JsonDataToNote
---@field private id number
---@field  idMetaData number
---@field  idNote number
---@field  json string
JsonDataToNote = {
	id = 0,
	idMetaData = 0,
	idNote = 0,
	json = "",
}

function JsonDataToNote:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.json = row["json"]
	return newObject
end

---@return number
function JsonDataToNote:getId()
	return self.id
end

---@param aIdMetaData number
---@param aIdNote number
---@return JsonDataToNote
function JsonDataToNote.get(aIdMetaData, aIdNote)
	local row = { idMetaData = aIdMetaData, idNote = aIdNote }
	local entries = database.JsonDataToNote:get({ where = row })
	if #entries == 1 then
		for _, entry in pairs(entries) do
			return JsonDataToNote:new(entry)
		end
	end
	return JsonDataToNote:new({ id = -1, idMetaData = aIdMetaData, idNote = aIdNote })
end

---@param json string
function JsonDataToNote:update(json)
	if self.id == -1 then
		local rowId = database.JsonDataToNote:insert({
			idMetaData = self.idMetaData,
			idNote = self.idNote,
			json = json,
		})
	else
		database.JsonDataToNote:update({
			where = { id = self.id },
			set = { json = json },
		})
	end
end

function JsonDataToNote.delete(conditions)
	database.JsonDataToNote:remove({ where = conditions })
end

return JsonDataToNote
