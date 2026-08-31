vim.opt.runtimepath:prepend(vim.fn.getcwd())
local data_path = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data_path .. "/lazy/sqlite.lua")

Config = require("MetaFly.config")
local Note = require("MetaFly.model.Note")

describe("MetaFly.model.Note", function()
	describe("Note.isMetaData", function()
		it("returns false for core note fields", function()
			assert.is_false(Note.isMetaData("id"))
			assert.is_false(Note.isMetaData("idNoteBox"))
			assert.is_false(Note.isMetaData("noteId"))
			assert.is_false(Note.isMetaData("title"))
			assert.is_false(Note.isMetaData("type"))
			assert.is_false(Note.isMetaData("status"))
			assert.is_false(Note.isMetaData("tags"))
			assert.is_false(Note.isMetaData("fileName"))
			assert.is_false(Note.isMetaData("created"))
			assert.is_false(Note.isMetaData("lastUpdated"))
		end)

		it("returns true for custom metadata fields", function()
			assert.is_true(Note.isMetaData("project"))
			assert.is_true(Note.isMetaData("author"))
			assert.is_true(Note.isMetaData("context"))
		end)

		it("noteId is not duplicated (counted as metadata only once)", function()
			-- Previously noteId appeared twice; ensure it is still classified as a Note field
			assert.is_false(Note.isMetaData("noteId"))
		end)
	end)

	describe("Note.saveValues with special-character titles", function()
		local testConfig = {
			database = "tests/TestData/MetaFly/note_spec_metadata.db",
			views = "tests/TestData/MetaFly/Views/",
			logger = {
				level = "debug",
				logFile = "tests/TestData/MetaFly/logs/metafly.log",
			},
			noteBoxes = {
				{
					name = "TestData",
					path = "tests/TestData",
					maxdepth = 3,
					ignored = { "MetaFly", "ignored", "Views" },
				},
			},
		}

		vim.fn.mkdir(vim.fn.fnamemodify(testConfig.database, ":h"), "p")
		vim.fn.mkdir(vim.fn.fnamemodify(testConfig.logger.logFile, ":h"), "p")
		os.remove(testConfig.database)

		Config:getInstance():setOptions(testConfig)

		it("saves a note with parentheses and dots in the title without SQL error", function()
			local values = {
				idNoteBox = "1",
				noteId = "test-special-title",
				title = "26.3-2(16.07-29.07)",
				type = "note",
				status = "active",
				fileName = "special.md",
				created = tostring(os.time()),
			}

			local db = require("MetaFly.model.database"):getInstance()

			-- Ensure the NoteBox row exists so the FK constraint is satisfied
			local nbId = db.NoteBox:insert({ name = "TestData", path = "tests/TestData" })
			values.idNoteBox = nbId

			local ok, result = pcall(Note.saveValues, values)
			assert.is_true(ok, "Note.saveValues raised an error: " .. tostring(result))
			assert.is_not_nil(result, "Expected a Note object to be returned")
			assert.equals("26.3-2(16.07-29.07)", result.title)
		end)

		it("saves a note with single-quotes in the title without SQL error", function()
			local db = require("MetaFly.model.database"):getInstance()
			local nbId = db.NoteBox:insert({ name = "TestData2", path = "tests/TestData2" })

			local values = {
				idNoteBox = nbId,
				noteId = "test-quotes",
				title = "it's a test: O'Brien",
				type = "note",
				status = "active",
				fileName = "quotes.md",
				created = tostring(os.time()),
			}

			local ok, result = pcall(Note.saveValues, values)
			assert.is_true(ok, "Note.saveValues raised an error: " .. tostring(result))
			assert.is_not_nil(result)
			assert.equals("it's a test: O'Brien", result.title)
		end)
	end)
end)
