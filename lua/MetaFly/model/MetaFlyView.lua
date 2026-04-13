local SqlBulider = require("MetaFly.utils.SqlBuilder")
local logger = require("MetaFly.config"):getInstance():getLogger("MetaFlyView")
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
---@field public groupBy string|table
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
	newObject.inherit = values["inherits"]
	newObject.orderBy = values["orderBy"]
	newObject.groupBy = values["groupBy"]
	newObject.limit = values["limit"]

	logger:debug(
		"Created MetaFlyView with name: " .. newObject.name .. " and where clause: " .. tostring(newObject.where)
	)
	return newObject
end

---@return string|nil
function MetaFlyView:getSelectStatement()
	local builder = SqlBuilder:new()
	return builder
		:withColumns(self.columns)
		:withFrom(self.from)
		:withWhere(self.where)
		:withInherits(self.inherit)
		:withOrderBy(self.orderBy)
		:withLimit(self.limit)
		:withGroupBy(self.groupBy)
		:build()
end

function MetaFlyView:getViewData()
	local statement = self:getSelectStatement()
	logger:debug("Executing SQL statement for view '" .. self.name .. "': " .. tostring(statement))
	logger:debug("SQL mode for view '" .. self.name .. "': " .. tostring(self.sqlMode))
	local database = require("MetaFly.model.database"):getInstance()
	local sqlResult = database:callSql(statement, self.sqlMode)
	local lines = {}

	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			table.insert(lines, line)
		end
		sqlResult:close()
	else
		lines = { "No results returned" }
	end
	return lines
end

return MetaFlyView
