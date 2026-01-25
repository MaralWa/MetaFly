local uv = vim.loop

local NotesIterator = require("MetaFly.utils.NotesIterator")

describe("MetaFly.utils.NotesIterator", function()
	local config = {
		path = "tests/TestData",
		ignored = { "Ignored" },
		maxdepth = 2,
		name = "TestData",
	}

	local expected_notes = {}
	local expected_names = {
		"251029202020.md",
		"251130171717.md",
		"task.md",
		"another_project.md",
		"some_project.md",
		"240302011450.md",
		"diary.md",
	}
	for _, name in ipairs(expected_names) do
		expected_notes[name] = true
	end

	it("iterates over notes in the directory TestData", function()
		local noOfFoundNotes = 0
		local iterator = NotesIterator:new(config)
		local note = nil
		repeat
			note = iterator:next()
			if note then
				noOfFoundNotes = noOfFoundNotes + 1
				expected_notes[note.name] = true
			end
		until not note

		assert.are.equal(#expected_names, noOfFoundNotes, "Number of found notes does not match expected")
	end)
end)
