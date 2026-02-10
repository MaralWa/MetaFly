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
end)
