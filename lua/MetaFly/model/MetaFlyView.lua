local SqlBuilder = require("MetaFly.utils.SqlBuilder")
local logger = require("MetaFly.config"):getInstance():getLogger().child("model").child("MetaFlyView")
local MetaFlyView = {}
MetaFlyView.__index = MetaFlyView

---@class MetaFlyView
---@field public name string
---@field public type string
---@field public description string
---@field public columns string|table
---@field public from string|table
---@field public where string
---@field public inherits string|table
---@field public orderBy string|table
---@field public limit number
---@field public groupBy string|table
---@field public sqlMode string

---@param values table
---@return MetaFlyView
function MetaFlyView.new(values)
	local self = setmetatable({}, MetaFlyView)

	-- Object initialization
	self.name = values["name"]
	self.type = values["type"]
	self.description = values["description"]
	self.columns = vim.deepcopy(values["columns"])
	self.from = values["from"]
	self.where = values["where"]
	self.sqlMode = values["sqlMode"]
	self.inherits = values["inherits"]
	self.orderBy = values["orderBy"]
	self.groupBy = values["groupBy"]
	self.limit = values["limit"]

	return self
end

---@return string|nil
function MetaFlyView:getSelectStatement()
	local builder = SqlBuilder:new()
	return builder
		:withColumns(self.columns)
		:withFrom(self.from)
		:withWhere(self.where)
		:withInherits(self.inherits)
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
