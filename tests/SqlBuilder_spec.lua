local uv = vim.loop

local SqlBuilder = require("MetaFly.utils.SqlBuilder")

describe("MetaFly.utils.SqlBuilder", function()
	it("creates a new SqlBuilder object", function()
		local sb = SqlBuilder:new()
		local statement = sb:withColumns({ "fullFileName", "Note.title" }):withLimit(10):build()

		local expectedStatement =
			"SELECT NoteBox.path || '/' || Note.fileName AS fullFileName, Note.title FROM NoteBox, Note WHERE Note.idNoteBox = NoteBox.id LIMIT 10"
		assert.equals(expectedStatement, statement)
	end)

	it("keeps double quotes in generated SQL", function()
		local sb = SqlBuilder:new()
		local statement = sb:withColumns({ "Note.title" }):withFrom({ "NoteBox" })
			:withWhere('NoteBox.name = "Some NoteBox"')
			:build()

		assert.equals('SELECT Note.title FROM NoteBox WHERE NoteBox.name = "Some NoteBox"', statement)
	end)
end)
