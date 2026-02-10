local uv = vim.loop

local ViewFactory = require("MetaFly.view.ViewFactory")

describe("MetaFly.view.ViewFactory", function()
	it("creates a PickerView correctly", function()
		local picker = ViewFactory.readFromFile("tests/TestData/Views/NotesPicker.yaml")
		assert.is_not_nil(picker, "PickerView should not be nil")
		assert.are.equal("Picker", picker.type, "View type should be PickerView")
		assert.are.same(
			{ "Note.title", "NoteBox.path || '/' || Note.fileName" },
			picker.columns,
			"Columns do not match expected"
		)
		assert.are.equal("Note, NoteBox", picker.from, "From clause does not match expected")
		assert.are.equal("csv", picker.sqlMode, "SQL mode does not match expected")
		assert.are.same(
			'Note.idNoteBox = NoteBox.id and NoteBox.name = "Some NoteBox"',
			picker.where,
			"Where clause does not match expected"
		)
	end)
end)
