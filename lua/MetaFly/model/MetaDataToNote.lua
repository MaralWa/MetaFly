local logger = require("MetaFly.config"):getInstance():getLogger("MetaDataToNote")

---@class MetaDataToNote
---@field private id number
---@field  idMetaData number
---@field  idNote number
---@field index number
---@field  value string
MetaDataToNote = {
	id = 0,
	idMetaData = 0,
	idNote = 0,
	index = 0,
	value = "",
}

function MetaDataToNote:new(row)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.id = row["id"]
	newObject.idMetaData = row["idMetaData"]
	newObject.idNote = row["idNote"]
	newObject.value = row["value"]
	newObject.index = row["index"]
	return newObject
end

---@return number
function MetaDataToNote:getId()
	return self.id
end

---@param aIdMetaData number
---@param aIdNote number
---@return MetaDataToNote
function MetaDataToNote.get(aIdMetaData, aIdNote)
	logger.fmt_debug("Getting MetaDataToNote with idMetaData %d and idNote %d", aIdMetaData, aIdNote)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	local row = { idMetaData = aIdMetaData, idNote = aIdNote }
	local entries = sqlite.MetadataToNote:get({ where = row })
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
	return MetaDataToNote:new({ id = -1, idMetaData = aIdMetaData, idNote = aIdNote })
end

---@param newValue string
function MetaDataToNote:update(newValue)
	local sqlite = require("MetaFly.model.database"):getInstance():getSqlite()
	logger.fmt_debug(
		"Updating MetaDataToNote with id %d, idMetaData %d, idNote %d, value %s",
		self.id,
		self.idMetaData,
		self.idNote,
		newValue
	)
	if self.id == -1 then
		local newRow = {}
		newRow.idMetaData = self.idMetaData
		newRow.idNote = self.idNote
		newRow.value = newValue
		self.id = sqlite.MetadataToNote:insert(newRow)
	else
		sqlite.MetadataToNote:update({
			where = { id = self.id },
			set = { value = newValue },
		})
	end
end

return MetaDataToNote
