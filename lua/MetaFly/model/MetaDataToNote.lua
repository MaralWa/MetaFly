local database = require("MetaFly.model.database")
local logger = require("MetaFly.config"):getInstance():getLogger("MetaDataToNote")

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

---@param aIdNote number
---@param aMetaDataIds number[]
function MetaDataToNote.deleteOther(aIdNote, aMetaDataIds)
	local deleteQuery = "DELETE from MetaDataToNote where idNote = "
		.. aIdNote
		.. " AND idMetaData not in ("
		.. table.concat(aMetaDataIds, ",")
		.. ")"

	print("Deleting MetaDataToNote for note " .. aIdNote .. " and meta data ids " .. vim.inspect(aMetaDataIds))
	database:getInstance():select(deleteQuery)
end

function MetaDataToNote.count(conditions)
	print("Counting MetaDataToNote with conditions: " .. vim.inspect(conditions))
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
		self.id = database.MetaDataToNote:insert(newRow)
	else
		database.MetaDataToNote:update({
			where = { id = self.id },
			set = { value = newValue },
		})
	end
end

return MetaDataToNote
