require("MetaFly.model.YamlHeader")

local logger = require("MetaFly.config"):getInstance():getLogger("Note")

local database = require("MetaFly.model.database")

---@class Note
---@field private id number
---@field private idNoteBox number
---@field private noteId string
---@field public title string
---@field public type string
---@field public context string
---@field public status string
---@field public fileName string
---@field public created number
---@field public lastUpdated number
---@field public tags string
local Note = {
	id = 0,
	idNoteBox = 0,
	noteId = "",
	title = "",
	type = "",
	context = "",
	status = "",
	fileName = "",
	created = 0,
	lastUpdated = 0,
	tags = "",
}

function Note.isMetaData(property)
	if
		property == "id"
		or property == "idNoteBox"
		or property == "noteId"
		or property == "title"
		or property == "type"
		or property == "status"
		or property == "tags"
		or property == "fileName"
		or property == "created"
		or property == "lastUpdated"
	then
		return false
	end
	return true
end

---@param values table
---@return Note
function Note:new(values)
	local newObject = setmetatable({}, self)
	self.__index = self

	-- Object initialization
	newObject.id = values["id"]
	newObject.idNoteBox = values["idNoteBox"]
	newObject.noteId = values["noteId"]
	newObject.title = values["title"]
	newObject.type = values["type"]
	newObject.context = values["context"]
	newObject.status = values["status"]
	newObject.fileName = values["fileName"]
	newObject.created = values["created"]
	newObject.lastUpdated = values["lastUpdated"]
	newObject.tags = values["tags"]
	return newObject
end

---@return number
function Note:getId()
	return self.id
end

---@return number
function Note:getIdNoteBox()
	return self.idNoteBox
end

---@return string
function Note:getNoteId()
	return self.noteId
end

---@param pWhere  table|nil
---@return integer
function Note.count(pWhere)
	local rows
	if pWhere == nil then
		rows = database.Note:get()
	else
		rows = database.Note:get({ where = pWhere })
	end
	return #rows
end

---@param idNoteBox number
---@param noteId string
---@return Note
function Note.getNoteWithId(idNoteBox, noteId)
	local row = {}
	row["idNoteBox"] = idNoteBox
	row["noteId"] = noteId
	local selectedRows = database.Note:get({ where = row })
	if #selectedRows == 1 then
		for _, values in pairs(selectedRows) do
			return Note:new(values)
		end
	end
	row.id = -1
	local newNote = Note:new(row)
	return newNote
end

---Normalise values before storing them in sqlite so that text fields are
---always proper Lua strings and idNoteBox is a number.  This prevents
---sqlite.lua from raw-interpolating values that look like SQL expressions
---(e.g. "26.3-2(16.07-29.07)") instead of binding them as parameters.
---@param values table
---@return table
local function sanitiseValues(values)
	local textFields = { "noteId", "title", "type", "context", "status", "tags", "fileName", "created", "lastUpdated" }
	local result = {}
	for k, v in pairs(values) do
		result[k] = v
	end
	result.idNoteBox = values["idNoteBox"] ~= nil and tonumber(values["idNoteBox"]) or nil
	for _, field in ipairs(textFields) do
		if result[field] ~= nil then
			result[field] = tostring(result[field])
		end
	end
	return result
end

---Insert a note row using an explicit parameterised statement so that field
---values with special characters (parentheses, dots, apostrophes …) are
---always safely bound rather than raw-interpolated into the SQL string.
---@param values table
---@return number  last inserted row id
local function insertNote(values)
	local db = database:getInstance():getSqlite()
	db:eval(
		[[INSERT INTO Note
			(noteId, title, type, context, status, tags, fileName, idNoteBox, created, lastUpdated)
		VALUES
			(:noteId, :title, :type, :context, :status, :tags, :fileName, :idNoteBox, :created, :lastUpdated)]],
		values
	)
	local row = db:eval("SELECT last_insert_rowid() AS id")
	return row[1].id
end

---Update a note row using an explicit parameterised statement.
---@param id number
---@param values table
local function updateNote(id, values)
	local db = database:getInstance():getSqlite()
	local bound = vim.tbl_extend("force", values, { id = id })
	db:eval(
		[[UPDATE Note SET
			noteId = :noteId,
			title = :title,
			type = :type,
			context = :context,
			status = :status,
			tags = :tags,
			fileName = :fileName,
			idNoteBox = :idNoteBox,
			created = :created,
			lastUpdated = :lastUpdated
		WHERE id = :id]],
		bound
	)
end

---@param values table
---@return Note | nil
function Note.saveValues(values)
	logger.debug("Saving note data: " .. vim.inspect(values))
	values = sanitiseValues(values)
	local row = { idNoteBox = values["idNoteBox"], noteId = values["noteId"] }
	local selectedRow = database.Note:get({
		where = row,
	})
	if #selectedRow == 0 then
		local idNote = insertNote(values)
		values.id = idNote
		return Note:new(values)
	elseif #selectedRow == 1 then
		for _, rowValues in pairs(selectedRow) do
			logger.debug("Note already exists with values " .. vim.inspect(rowValues))
			updateNote(rowValues.id, values)
			values.id = rowValues.id
			return Note:new(values)
		end
	else
		return nil
	end
end

---@param values table
function Note:update(values)
	values = sanitiseValues(values)
	values["lastUpdated"] = tostring(os.time())
	if self.id == -1 then
		self.id = insertNote(values)
	else
		updateNote(self.id, values)
	end
	self.title = values["title"]
	self.type = values["type"]
	self.context = values["context"]
	self.status = values["status"]
	self.fileName = values["fileName"]
	self.created = values["created"]
	self.lastUpdated = values["lastUpdated"]
	self.tags = values["tags"]
end

return Note
