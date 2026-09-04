local Config = require("MetaFly.config")
local NoteBox = require("MetaFly.model.NoteBox")
local YamlHeader = require("MetaFly.model.YamlHeader")
local NotesIterator = require("MetaFly.utils.NotesIterator")
local DatabaseController = require("MetaFly.controller.DatabaseController")

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
				DatabaseController.updateNote(note.path, noteBox, yamlHeader)
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
