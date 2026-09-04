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

local logger = Config:getInstance():getLogger("DatabaseController")

local requiredNoteData = {
	"noteId",
	"title",
}

local DatabaseController = {}

---@param noteData table
---@return boolean, table
function DatabaseController.hasRequiredData(noteData)
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

---@param note Note
---@param metaData MetaData
---@param values table
function DatabaseController.saveMetaData(note, metaData, values)
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

---@param note Note
---@param metaData table
function DatabaseController.updateMetaData(note, metaData)
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
		DatabaseController.saveMetaData(note, metaDataRow, metaDataValues)
	end

	database:getInstance():deleteOther("MetaDataToNote", note:getId(), metaDataIds)
	database:getInstance():deleteOther("JsonDataToNote", note:getId(), metaDataIds)
end

---@param fileName string
---@param noteBox NoteBox
---@param yamlHeader YamlHeader
function DatabaseController.updateNote(fileName, noteBox, yamlHeader)
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
	local hasRequired, errors = DatabaseController.hasRequiredData(noteData)
	if not hasRequired then
		logger.debug("Cannot update note because of missing required data")
		table.insert(errors, 1, "Cannot update note:" .. fileName)
		return
	end
	local note = Note.saveValues(noteData)
	if note == nil then
		logger.error("Failed to save note for file: " .. fileName)
		return
	end

	DatabaseController.updateMetaData(note, yamlHeader:getMetaData())
end

---@param noteBox NoteBox
function DatabaseController.updateNoteBox(noteBox)
	local notesIterator = NotesIterator:new(noteBox)
	local note = notesIterator:next()
	while note ~= nil do
		logger.info("Found note: " .. note.path)
		local yamlHeader, errorMsg = YamlHeader:getFromFile(note.path)
		if errorMsg ~= nil then
			logger.debug("Cannot read YAML header from note: " .. note.path .. " because of error: " .. errorMsg)
		else
			DatabaseController.updateNote(note.path, noteBox, yamlHeader)
		end
		note = notesIterator:next()
	end
	noteBox:markAsUpdated()
end

return DatabaseController
