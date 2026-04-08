local SqlBulider = require("MetaFly.utils.SqlBuilder")

local MetaFlyView = {}

---@class MetaFlyView
---@field public name string
---@field public type string
---@field public description string
---@field public columns string|table
---@field public from string|table
---@field public where string
---@field public inherit string|table
---@field public orderBy string|table
---@field public limit number
---@field public sqlMode string

---@param values table
---@return MetaFlyView
function MetaFlyView:new(values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.name = values["name"]
	newObject.type = values["type"]
	newObject.description = values["description"]
	newObject.columns = vim.deepcopy(values["columns"])
	newObject.from = values["from"]
	newObject.where = values["where"]
	newObject.sqlMode = values["sqlMode"]

	return newObject
end

---@return string|nil
function MetaFlyView:getSelectStatement()
	local builder = SqlBuilder:new()
	return builder
		:withColumns(self.columns)
		:withFrom(self.from)
		:withWhere(self.where)
		:withInherit(self.inherit)
		:withOrderBy(self.orderBy)
		:withLimit(self.limit)
		:build()
end

return MetaFlyView
