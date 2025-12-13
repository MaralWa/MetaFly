local lyaml = require("lyaml")

local MetaFlyView = {}

---@class MetaFlyView
---@field public name string
---@field public type string
---@field public description string
---@field public columns table
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
	newObject.where = values["where"]
	newObject.sqlMode = values["sqlMode"]

	return newObject
end

---@type MetaFlyView
MetaFlyView.DefaultPicker = MetaFlyView:new({
	name = "DefaultView",
	type = "Picker",
	description = "Alle MetaFly Notizen",
	columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" },
	where = "Note.idNoteBox = NoteBox.id and NoteBox.id",
	sqlMode = "csv",
})

---@param fileName string
---@return MetaFlyView|nil
function MetaFlyView:readFromFile(fileName)
	local viewFile = io.open(fileName, "r")
	if viewFile == nil then
		print("viewFile ist null")
		return nil
	end
	local viewYaml = viewFile:read("*all")
	viewFile:close()
	local viewData = lyaml.load(viewYaml)
	return MetaFlyView:new(viewData)
end

---@return string|nil
function MetaFlyView:getSelectStatement()
	local selectStatement = "select "
	if self.columns ~= nil and self.where ~= nil then
		selectStatement = selectStatement
			.. table.concat(self.columns, ", ")
			.. " from NoteBox, Note"
			.. " where "
			.. self.where
		return selectStatement
	else
		return nil
	end
end

return MetaFlyView
