local uv = vim.loop

local PickerView = require("MetaFly.model.PickerView")

describe("MetaFly.model.PickerView", function()
	it("Check DefaultPicker", function()
		local pickerView = PickerView.DefaultPicker

		assert.equals("DefaultView", pickerView.name)
		assert.equals("Picker", pickerView.type)
		assert.equals("All Metafly notes", pickerView.description)
		assert.equals("csv", pickerView.sqlMode)
		local sqlStatement = pickerView:getSelectStatement()
		local expectedStatement =
			"SELECT Note.title, NoteBox.path || '/' || Note.fileName AS fullFileName FROM NoteBox, Note WHERE Note.idNoteBox = NoteBox.id"
		assert.equals(expectedStatement, sqlStatement)
	end)
end)
