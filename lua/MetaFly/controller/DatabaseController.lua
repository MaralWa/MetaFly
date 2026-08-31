local Config = require("MetaFly.config")
local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local JsonDataToNote = require("MetaFly.model.JsonDataToNote")
local YamlHeader = require("MetaFly.model.YamlHeader")
local NotesIterator = require("MetaFly.utils.NotesIterator")
local utils = require("MetaFly.utils.utils")

local DatabaseController = {}

---@param noteBox NoteBox
function DatabaseController.updateNoteBox(noteBox)
	local notesIterator = NotesIterator:new(noteBox)
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
end

return DatabaseController
