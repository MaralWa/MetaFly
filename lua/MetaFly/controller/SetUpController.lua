local Config = require("MetaFly.config")
local database = require("MetaFly.model.database")
local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local JsonDataToNote = require("MetaFly.model.JsonDataToNote")
local YamlHeader = require("MetaFly.model.YamlHeader")
local NotesIterator = require("MetaFly.utils.NotesIterator")
local utils = require("MetaFly.utils.utils")

local requiredNoteData = {
	"noteId",
	"title",
}

local logger = Config:getInstance():getLogger()

---@class SetUpController
local SetUpController = {}

function SetUpController:new()
	logger = require("MetaFly.config"):getInstance():getLogger()
	local newObject = setmetatable({}, self)
	self.__index = self

	return newObject
end

---@param note Note
function SetUpController:logNote(note)
	if note ~= nil then
		logger.info("Saved note with id " .. note:getId() .. " and title " .. note.title)
	else
		logger.error("Failed to save note")
	end
end

---@param note Note
---@param metaData MetaData
---@param values table
function SetUpController:saveMetaData(note, metaData, values)
	logger.info("Saved meta data with id " .. metaData:getId() .. " and name " .. metaData.name)

	local metaDataCount = MetaDataToNote.count({ idMetaData = metaData:getId(), idNote = note:getId() })

	if #values < metaDataCount then
		logger.debug(
			"Meta data count for meta data "
				.. metaData.name
				.. " and note "
				.. note:getId()
				.. " is "
				.. metaDataCount
				.. " but only "
				.. #values
				.. " values provided. Deleting old meta data."
		)
		MetaDataToNote.deleteByPosition(metaData:getId(), note:getId(), #values)
	end

	logger.debug(
		"Meta data count for meta data " .. metaData.name .. " and note " .. note:getId() .. " is " .. metaDataCount
	)

	for position, value in pairs(values) do
		logger.debug("Meta data value " .. position .. ": " .. value)
		local metaDataToNote = MetaDataToNote.get(metaData:getId(), note:getId(), position)
		if metaDataToNote ~= nil then
			logger.debug(
				"Updating meta data " .. metaData.name .. " for note " .. note:getId() .. " and position " .. position
			)
			metaDataToNote:update(value)
		else
			logger.error(
				"Failed to get meta data "
					.. metaData.name
					.. " for note "
					.. note:getId()
					.. " and position "
					.. position
			)
		end
	end

	local jsonDataToNote = JsonDataToNote.get(metaData:getId(), note:getId())
	jsonDataToNote:update(vim.json.encode(values))
end

---comment
---@param note Note
---@param metaData table
function SetUpController:updateMetaData(note, metaData)
	logger.debug("Updating meta data for note " .. note:getId() .. " with meta data: " .. vim.inspect(metaData))
	local metaDataIds = {}
	for name, value in pairs(metaData) do
		local metaDataRow = MetaData.getByName(name)
		table.insert(metaDataIds, metaDataRow:getId())
		local metaDataValues = {}
		if type(value) == "string" then
			metaDataValues = { value }
		elseif type(value) == "number" or type(value) == "boolean" then
			metaDataValues = { tostring(value) }
		elseif type(value) == "table" and #value > 0 then
			metaDataValues = value
		end
		self:saveMetaData(note, metaDataRow, metaDataValues)
	end

	database:getInstance():deleteOther("MetaDataToNote", note:getId(), metaDataIds)
	database:getInstance():deleteOther("JsonDataToNote", note:getId(), metaDataIds)
end

---@param fileName string
---@param noteBox NoteBox
---@param yamlHeader YamlHeader
function SetUpController:updateNote(fileName, noteBox, yamlHeader)
	local noteData = yamlHeader:parseDocument()
	if noteData == nil then
		return
	end
	noteData.idNoteBox = "" .. noteBox:getId()
	noteData.fileName = noteBox:getRelativePath(fileName)
	if noteData.title == nil or noteData.title == "" then
		logger.debug("Using fileName as title: " .. fileName)
		noteData.title = utils.getFileNameWithoutExtension(fileName)
	end
	local hasRequired, errors = self:hasRequiredData(noteData)
	if not hasRequired then
		logger.debug("Canno update note because of missing required data")
		table.insert(errors, 1, "Cannot update note:" .. fileName)
		return
	end
	local note = Note.saveValues(noteData)
	if note == nil then
		logger.error("Failed to save note for file: " .. fileName)
		return
	end

	self:updateMetaData(note, yamlHeader:getMetaData())
end

---@param noteData table
---@return boolean, table
function SetUpController:hasRequiredData(noteData)
	local errors = {}
	local result = true
	for _, key in ipairs(requiredNoteData) do
		if noteData[key] == nil or type(noteData[key]) ~= "string" or noteData[key] == "" then
			result = false
			table.insert(errors, "- value for " .. key .. " is missing ")
		end
	end
	return result, errors
end

-- @param noteboxConfig configuration for single notebox
function SetUpController:scanNoteBox(noteBoxConfig)
	local notesIterator = NotesIterator:new(noteBoxConfig)
	local noteBox, noteBoxinserted = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
	local lastUpdated = noteBox:getLastUpdatedTimeStamp()
	local note = notesIterator:next()
	while note ~= nil do
		logger.info("Found note: " .. note.path)
		if false and not noteBoxinserted and note.modified < lastUpdated then
			logger.debug("Skipping note " .. note.path .. " because it was not modified since last scan.")
			print("Note was not modified since last scan.")
		else
			local yamlHeader, errorMsg = YamlHeader:getFromFile(note.path)
			if errorMsg ~= nil then
				logger.debug("Cannot read YAML header from note: " .. note.path .. " because of error: " .. errorMsg)
			else
				self:updateNote(note.path, noteBox, yamlHeader)
			end
		end
		note = notesIterator:next()
	end
	noteBox:markAsUpdated()
	return noteBox
end

---@return table
---@param noteboxConfigs table
function SetUpController:scanNoteBoxes(noteboxConfigs)
	local noteBoxes = {}
	for _, noteBoxConfig in pairs(noteboxConfigs) do
		logger.debug("NoteBox " .. noteBoxConfig["name"])
		local noteBoxName = noteBoxConfig["name"]
		local noteBoxPath = string.sub(noteBoxConfig["path"], -1, -1) ~= "/" and noteBoxConfig["path"]
			or string.sub(noteBoxConfig["path"], 1, -2)
		local noteBox = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
		logger.debug("NoteBox ID " .. noteBox:getId())
		logger.debug("NoteBox lastUpdated " .. noteBox:getLastUpdated())
		local idNoteBox = noteBox:getId()
		local whereNotes = {}
		whereNotes["idNoteBox"] = idNoteBox
		noteBoxes[noteBoxPath] = self:scanNoteBox(noteBoxConfig)
	end
	return noteBoxes
end

return SetUpController
