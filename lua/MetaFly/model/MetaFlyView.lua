local MetaFlyView = {}

---@class MetaFlyView
---@field public name string
---@field public type string
---@field public description string
---@field public columns table
---@field public from string
---@field public where string
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
	local selectStatement = "select "
	if self.columns ~= nil and self.where ~= nil then
		selectStatement = selectStatement
			.. table.concat(self.columns, ", ")
			.. " from "
			.. self.from
			.. " where "
			.. table.concat(self.where, " and ")
		return selectStatement
	else
		return nil
	end
end

return MetaFlyView
