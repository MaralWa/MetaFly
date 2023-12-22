local database = require("MetaFly.model.database")

---@class MetaData
---@field id number
---@field name string
---@field type string
local MetaData = {
	id = 0,
	name = "",
	type = "",
}

---@param id number
---@param values table
---@return (MetaData)
function MetaData:new(id, values)
	local newObject = setmetatable({}, self)
	self.__index = self
	newObject.id = id
	newObject.name = values["name"]
	newObject.type = values["type"]
	return newObject
end

---comment
---@return number
function MetaData:getId()
	return self.id
end

---comment
---@param name string
---@param type string | nil
---@return MetaData
function MetaData.getByName(name, type)
	local metaData = database.Metadata:get({ name = name })
	if #metaData == 1 then
		for rowId, values in pairs(metaData) do
			return MetaData:new(rowId, values)
		end
	end
	local inseertValus = {
		name = name,
		type = type ~= nil and type or "",
	}
	if type ~= nil then
	end
	local id = database.Metadata:insert(inseertValus)
	return MetaData:new(id, inseertValus)
end

return MetaData
