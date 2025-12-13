local sqlite = require("sqlite.db")
local tbl = require("sqlite.tbl")
local MetaFlyPopUp = require("MetaFly.view.MetaFlyPopUp")

local NotesPickerController = {}

function NotesPickerController:selectNotes()
	local popup = MetaFlyPopUp:new()
	local notes = sqlite.db:eval(
		"select Note.title, NoteBox.path || '/' || Note.fileName from Note, NoteBox where Note.idNoteBox = NoteBox.id limit 10"
	)
	if type(notes) == "table" then
		popup:appendLines(TableUtils.convertToLines(notes))
	end
end

return NotesPickerController
