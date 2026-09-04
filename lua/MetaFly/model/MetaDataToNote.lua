local database = require("MetaFly.model.database")
local logger = require("MetaFly.config"):getInstance():getLogger()

---@class MetaDataToNote
---@field private id number
---@field  idMetaData number
---@field  idNote number
---@field position number
---@field  value string
local MetaDataToNote = {
	id = 0,
	idMetaData = 0,
	idNote = 0,
	position = 0,
	value = "",
}

---@param values table
---@return number  last inserted row id
local function insertMetaData(values)
	local db = database:getInstance():getSqlite()
	-- Order must match the column list in the INSERT statement below.
	local ordered = {
		tonumber(values.idMetaData),
		tonumber(values.idNote),
		tonumber(values.position),
		tostring(values.value),
	}
	local sqlstmt = require("sqlite.stmt")
	local stmt = sqlstmt:parse(
		db.conn,
		"INSERT INTO MetaDataToNote (idMetaData, idNote, position, value) " .. " VALUES (?, ?, ?, ?)"
	)
	for i = 1, 10 do
		stmt:bind(i, ordered[i] ~= nil and ordered[i] or "")
	end
	stmt:step()
	stmt:finalize()
	local row = db:eval("SELECT last_insert_rowid() AS id")
	return row[1].id
end

---@param id number
---@param value string
local function updateMetaDataValue(id, value)
	local db = database:getInstance():getSqlite()
	local ordered = {
		tostring(value),
		tonumber(id),
	}
	local sqlstmt = require("sqlite.stmt")
	local stmt = sqlstmt:parse(db.conn, "UPDATE MetaDataToNote SET value=? WHERE id=?")
	for i = 1, 2 do
		stmt:bind(i, ordered[i] ~= nil and ordered[i] or "")
	end
	stmt:step()
	stmt:finalize()
end

function MetaDataToNote:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.value = row["value"]
	newObject.position = row["position"]
	return newObject
end

---@return number
function MetaDataToNote:getId()
	return self.id
end

---@param aIdMetaData number
---@param aIdNote number
---@param aPosition number
---@return MetaDataToNote
function MetaDataToNote.get(aIdMetaData, aIdNote, aPosition)
	logger.fmt_debug("Getting MetaDataToNote with idMetaData %d and idNote %d", aIdMetaData, aIdNote)
	local row = { idMetaData = aIdMetaData, idNote = aIdNote, position = aPosition }
	local entries = database.MetaDataToNote:get({ where = row })
	logger.fmt_debug(
		"Found %d entries for MetaDataToNote with idMetaData %d and idNote %d",
		#entries,
		aIdMetaData,
		aIdNote
	)
	logger.fmt_debug("Entries: %s", vim.inspect(entries))
	if #entries == 1 then
		for _, entry in pairs(entries) do
			return MetaDataToNote:new(entry)
		end
	end
	return MetaDataToNote:new({ id = -1, idMetaData = aIdMetaData, idNote = aIdNote, position = aPosition, value = "" })
end

function MetaDataToNote.count(conditions)
	local results = database.MetaDataToNote:get({ where = conditions })
	return #results
end

---@param newValue string
function MetaDataToNote:update(newValue)
	logger.fmt_debug(
		"Updating MetaDataToNote with id %d, idMetaData %d, idNote %d, position %d, value %s",
		self.id,
		self.idMetaData,
		self.idNote,
		self.position,
		newValue
	)
	if self.id == -1 then
		local newRow = {}
		newRow.idMetaData = self.idMetaData
		newRow.idNote = self.idNote
		newRow.position = self.position
		newRow.value = newValue
		self.id = insertMetaData(newRow)
	else
		updateMetaDataValue(self.id, newValue)
	end
end

---Deletes all MetaDataToNote entries for a given metaData/note combination
---whose position exceeds maxPosition.
---@param idMetaData number
---@param idNote number
---@param maxPosition number
function MetaDataToNote.deleteByPosition(idMetaData, idNote, maxPosition)
	local deleteQuery = string.format(
		"DELETE FROM MetaDataToNote WHERE idMetaData = %d AND idNote = %d AND position > %d",
		idMetaData,
		idNote,
		maxPosition
	)
	database:getInstance():select(deleteQuery)
end

return MetaDataToNote
