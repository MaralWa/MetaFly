local logger = require("MetaFly.config").getInstance():getLogger("SqlBuilder")

SqlBuilder = {}

local columnSnippets = {
	fullFileName = {
		statement = "NoteBox.path || '/' || Note.fileName",
		tables = { "NoteBox", "Note" },
		condition = "Note.idNoteBox = NoteBox.id",
	},
	markdownLink = {
		statement = "'[' || Note.title || '](' || Note.fileName || ')'",
		tables = { "Note" },
		condition = nil,
	},
	fullMarkdownLink = {
		statement = "'[' || Note.title || '](' || NoteBox.path || '/' || Note.fileName || ')'",
		tables = { "NoteBox", "Note" },
		condition = "Note.idNoteBox = NoteBox.id",
	},
	wikkiLink = {
		statement = "'[[' || Note.title || ']]'",
		tables = { "Note" },
		condition = nil,
	},
	fullWikkiLink = {
		statement = "'[[' || NoteBox.path || '/' || Note.title || ']]'",
		tables = { "NoteBox", "Note" },
		condition = "Note.idNoteBox = NoteBox.id",
	},
	tags = "group_concat(Tag.name, ', ')",
}

local AllowedInherits = {
	"Note.idNoteBox",
	"Note.type",
	"Note.status",
	"Note.context",
}

---@class SqlBuilder
---@field public columns table
---@field public from table
---@field public where string
---@field public orderBy table
---@field public groupBy table
---@field public limit number

function SqlBuilder:new()
	local obj = {
		columns = {},
		from = {},
		where = "",
		groupBy = {},
		orderBy = {},
		limit = nil,
	}
	setmetatable(obj, self)
	self.__index = self
	return obj
end

function SqlBuilder:withColumns(cols)
	if cols == nil or #cols == 0 then
		return self
	end
	local fileName = vim.api.nvim_buf_get_name(0)
	for _, col in ipairs(cols) do
		if columnSnippets[col] then
			local columnSpec = columnSnippets[col]
			table.insert(self.columns, columnSpec.statement .. " AS " .. col)
			for _, tbl in ipairs(columnSpec.tables) do
				table.insert(self.from, tbl)
			end
			if columnSpec.condition then
				self:withWhere(columnSpec.condition)
			end
		else
			table.insert(self.columns, col)
		end
	end
	return self
end

function SqlBuilder:withFrom(tables)
	if tables == nil or #tables == 0 then
		return self
	end
	for _, tbl in ipairs(tables) do
		table.insert(self.from, tbl)
	end
	return self
end

function SqlBuilder:withWhere(condition)
	logger.debug("Adding WHERE condition: " .. tostring(condition)) -- Debug print
	if condition == nil or condition == "" then
		return self
	end
	if self.where == "" then
		self.where = condition
	else
		self.where = self.where .. " AND " .. condition
	end
	return self
end

function SqlBuilder:isValidInherit(inherit)
	for _, validInherit in ipairs(AllowedInherits) do
		if inherit == validInherit then
			return true
		end
	end
	return false
end

function SqlBuilder:withInherits(inherits)
	logger.debug("Processing inherits: " .. vim.inspect(inherits)) -- Debug print
	if inherits == nil or #inherits == 0 then
		return self
	end
	for _, inherit in ipairs(inherits) do
		if SqlBuilder:isValidInherit(inherit) then
			local bufferValue = require("MetaFly.model.database"):getInstance():getPropertyOfCurrentBuffer(inherit)
			if bufferValue ~= nil then
				self:withWhere(inherit .. " = '" .. bufferValue .. "'")
			else
				print("Warning: No value found for inherit condition: " .. inherit)
			end
		else
			print("Warning: Ignoring invalid inherit condition: " .. inherit)
		end
	end
	return self
end

function SqlBuilder:withOrderBy(cols)
	if cols == nil or #cols == 0 then
		return self
	end
	for _, col in ipairs(cols) do
		table.insert(self.orderBy, col)
	end
	return self
end

function SqlBuilder:withGroupBy(cols)
	if cols == nil or #cols == 0 then
		return self
	end
	for _, col in ipairs(cols) do
		table.insert(self.groupBy, col)
	end
	return self
end

function SqlBuilder:withLimit(lim)
	if lim == nil then
		return self
	end
	self.limit = lim
	return self
end

function SqlBuilder:build()
	local query = "SELECT " .. table.concat(self.columns, ", ") .. " FROM " .. table.concat(self.from, ", ")
	if self.where ~= "" then
		query = query .. " WHERE " .. self.where
	end
	if #self.orderBy > 0 then
		query = query .. " ORDER BY " .. table.concat(self.orderBy, ", ")
	end
	if self.limit then
		query = query .. " LIMIT " .. tostring(self.limit)
	end
	if #self.groupBy > 0 then
		query = query .. " GROUP BY " .. table.concat(self.groupBy, ", ")
	end
	print("Built SQL Query: " .. query) -- Debug print
	return query
end

return SqlBuilder
