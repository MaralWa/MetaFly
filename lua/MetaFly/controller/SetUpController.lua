local Config = require("MetaFly.config")
local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local YamlHeader = require("MetaFly.model.YamlHeader")
local TableUtils = require("MetaFly.utils.TableUtils")

local requiredNoteData = {
	"noteId",
	"title",
	"created",
}

local logger = Config:getInstance():getLogger()

---@class SetUpController
local SetUpController = {}

function SetUpController:new()
	local newObject = setmetatable({}, self)
	self.__index = self

	return newObject
end

---@param note Note
function SetUpController:logNote(note)
	logMsg = "Notiz - logNote: " .. note:getId() .. ", " .. note.title .. ", " .. note.fileName
end

---@param fileName string
---@param noteBox NoteBox
---@param yamlHeader YamlHeader
function SetUpController:updateNote(fileName, noteBox, yamlHeader)
	logger:debug("Updating note " .. fileName)
	local noteData = yamlHeader:parseDocument(noteBox)
	if noteData == nil then
		return
	end
	local hasRequired, errors = self:hasRequiredData(noteData)
	if not hasRequired then
		logger:debug("Canno update note because of missing required datat")
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
			else
				metaDataToNote:update(table.concat(value, ", "))
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

---@return table
---@param noteboxConfigs table
function SetUpController:scanNoteBoxes(noteboxConfigs)
	local noteBoxes = {}
	for index, noteBoxConfig in pairs(noteboxConfigs) do
		logger:debug("NoteBox " .. noteBoxConfig["name"])
		local noteBoxName = noteBoxConfig["name"]
		local noteBoxPath = string.sub(noteBoxConfig["path"], -1, -1) ~= "/" and noteBoxConfig["path"]
			or string.sub(noteBoxConfig["path"], 1, -2)
		local noteBox = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
		local idNoteBox = noteBox:getId()
		local whereNotes = {}
		whereNotes["idNoteBox"] = idNoteBox
		noteBoxes[noteBoxPath] = noteBox
		local findCommand, newNotes = noteBox:scanForNotes()
		for index, newNote in ipairs(newNotes) do
			local yamlHeader, errorMsg = YamlHeader:getFromFile(newNote)
			if errorMsg ~= nil then
			else
				self:updateNote(newNote, noteBox, yamlHeader)
			end
		end
		noteBox:markAsUpdated()
	end
	return noteBoxes
end

return SetUpController
