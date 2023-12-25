local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local MetaFlyPopUp = require("MetaFly.view.MetaFlyPopUp")
local YamlHeader = require("MetaFly.model.YamlHeader")
local TableUtils = require("MetaFly.utils.TableUtils")

local requiredNoteData = {
	"noteId",
	"title"
}
---@class SetUpController
---@field private popup MetaFlyPopUp
local SetUpController = {}

function SetUpController:new()
	local newObject = setmetatable({}, self)
	self.__index = self
	newObject.popup = MetaFlyPopUp:new()
	return newObject
end

---@param noteBox NoteBox
---@param yamlHeader YamlHeader
function SetUpController:updateNote(noteBox, yamlHeader)
	self.popup:appendLines(yamlHeader:getHeaderLines())
	yamlHeader:parseDocument()
	local noteData = yamlHeader:getNoteData
	local hasRequired, errors = self.hasRequiredData(noteData)
	if not hasRequired then
		table.insert(errors, 1, "Cannot update note:")
		self.popup:appendLines(errors)
		return
	end
	local note = Note.getNoteWithId(noteBox:getId(), noteData["noteId"])
	if note:getId() == -1 then
		noteData["fileName"] = noteBox:getRelativePath(yamlHeader:getFileName())
		self.popup:appendLine("neue Notiz; " .. noteData["fileName"])
	end
	note:upate(noteData)
	for name, value in pairs(yamlHeader:getMetaData()) do
		local metaDataRow = MetaData.getByName(name)
		self.popup:appendLine("MetaData.id: " .. metaDataRow:getId())
		local metaDataToNote = MetaDataToNote.get(metaDataRow:getId(), note:getId())
		self.popup:appendLines({
			"note.id: " .. note:getId(),
			"metaDataToNote.id: " .. metaDataToNote:getId(),
			"metaDataToNote.idMetaData: " .. metaDataToNote.idMetaData(),
			"metaDataToNote.idNote: " .. metaDataToNote.idNote(),
		})
		metaDataToNote:update(value)
	end
end

---@param notedata table
---@return boolean, table
function SetUpController:hasRequiredData(noteData)
	local errors = {}
	local result = true
	for _, key in ipairs(requiredNoteData) do
		if note[key] == nil or noteData[key] == "" then
			result = false
			table.insert(errors, "- value for " .. key .. "is missing ")
		end
	end
	return result, errors
end

---@return table
---@param noteboxConfigs table
function SetUpController:scanNoteBoxes(noteboxConfigs)
	local noteBoxes = {}
	self.popup:appendLine("Setting up MetaFly")
	self.popup:appendLine("")
	self.popup:open()
	self.popup:appendLines(TableUtils.convertToLines(noteboxConfigs))
	for index, noteBoxConfig in pairs(noteboxConfigs) do
		self.popup:appendLine("Box " .. index .. ": " .. type(noteBoxConfig))
		self.popup:appendLines(TableUtils.convertToLines(noteBoxConfig))
		local noteBoxName = noteBoxConfig["name"]
		local noteBoxPath = string.sub(noteBoxConfig["path"], -1, -1) ~= "/" and noteBoxConfig["path"]
			or string.sub(noteBoxConfig["path"], 1, -2)
		local noteBox = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
		self.popup:appendLine(
			noteBox:getName()
				.. ": "
				.. noteBox:getPath()
				.. "  "
				.. os.date("%Y-%m-%d %H:%M", noteBox:getLastUpdated())
				.. "  "
				.. noteBox:getNumberOfNotes()
				.. " notes "
		)
		noteBoxes[noteBoxPath] = noteBox
		local newNotes = noteBox:scanForNotes()
		self.popup:appendLine("new notes: " .. #newNotes)
		for index, newNote in ipairs(newNotes) do
			local yamlHeader, errorMsg = YamlHeader:getFromFile(newNote)
			if errorMsg ~= nil then
				self.popup:appendLine(newNote .. ": " .. errorMsg)
			else
				self:updateNote(noteBox, yamlHeader)
			end
			self.popup:appendLine("")
		end
	end
	return noteBoxes
end

return SetUpController
