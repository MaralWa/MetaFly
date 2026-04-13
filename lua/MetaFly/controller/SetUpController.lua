local Scanner = require("plenary.scandir")
local Config = require("MetaFly.config")
local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local YamlHeader = require("MetaFly.model.YamlHeader")
local NotesIterator = require("MetaFly.utils.NotesIterator")
local utils = require("MetaFly.utils.utils")

local requiredNoteData = {
	"noteId",
	"title",
}

local logger = nil

---@class SetUpController
local SetUpController = {}

function SetUpController:new()
	logger = require("MetaFly.config"):getInstance():getLogger("SetUpController")
	local newObject = setmetatable({}, self)
	self.__index = self

	return newObject
end

---@param note Note
function SetUpController:logNote(note)
	logger.info("Saved note with id " .. note:getId() .. " and title " .. note.title)
end

---@param fileName string
---@param noteBox NoteBox
---@param yamlHeader YamlHeader
function SetUpController:updateNote(fileName, noteBox, yamlHeader)
	local noteData = yamlHeader:parseDocument(noteBox)
	if noteData == nil then
		return
	end
	if noteData.title == nil or noteData.title == "" then
		logger.debug("Using fileName as title: " .. fileName)
		noteData.title = utils.getFileNameWithoutExtension(fileName)
	end
	local hasRequired, errors = self:hasRequiredData(noteData)
	if not hasRequired then
		logger.debug("Canno update note because of missing required datat")
		table.insert(errors, 1, "Cannot update note:" .. fileName)
		return
	end
	local note = Note.saveValues(noteData)
	if note ~= nil then
		self:logNote(note)
		for name, value in pairs(yamlHeader:getMetaData()) do
			local metaDataRow = MetaData.getByName(name)
			local metaDataToNote = MetaDataToNote.get(metaDataRow:getId(), note:getId())
			if type(value) == "string" then
				metaDataToNote:update(value)
			elseif type(value) == "number" then
				metaDataToNote:update(tostring(value))
			elseif type(value) == "boolean" then
				metaDataToNote:update(tostring(value))
			elseif type(value) == "table" and #value > 0 then
				metaDataToNote:update(vim.json.encode(value))
			else
				logger.debug("Cannot save meta data value of type " .. type(value) .. " for note " .. note:getId())
			end
		end
	end
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
		logger.debug("NoteBox lastUpdated " .. noteBox.lastUpdated)
		local idNoteBox = noteBox:getId()
		local whereNotes = {}
		whereNotes["idNoteBox"] = idNoteBox
		noteBoxes[noteBoxPath] = self:scanNoteBox(noteBoxConfig)
	end
	return noteBoxes
end

return SetUpController
