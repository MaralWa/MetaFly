-- Setup: Füge das aktuelle Verzeichnis und sqlite.lua zum runtimepath hinzu
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local data_path = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data_path .. "/lazy/sqlite.lua")

local uv = vim.loop

Database = require("MetaFly.model.database")
Config = require("MetaFly.config")
local NoteBox = require("MetaFly.model.NoteBox")
local Note = require("MetaFly.model.Note")
local MetaData = require("MetaFly.model.MetaData")
local MetaDataToNote = require("MetaFly.model.MetaDataToNote")
local JsonDataToNote = require("MetaFly.model.JsonDataToNote")

describe("Database", function()
	local testConfig = {
		database = "tests/TestData/MetaFly/metadata.db",
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

	local config = Config:getInstance()
	config:setOptions(testConfig)
	local logger = config:getLogger()

	-- Ensure required directories exist and start with a fresh database
	vim.fn.mkdir(vim.fn.fnamemodify(testConfig.database, ":h"), "p")
	vim.fn.mkdir(vim.fn.fnamemodify(testConfig.logger.logFile, ":h"), "p")
	os.remove(testConfig.database)

	local db = require("MetaFly.model.database"):getInstance()
	logger.info("MetaFly Database initialized at: " .. db:getUri())

	-- Create the SetUpController instance that performs the actual scanning
	local setUpController = require("MetaFly.controller.SetUpController"):new()
	local databaseController = require("MetaFly.controller.DatabaseController")
	it("Scanning of single note", function()
		assert.is_string(db:getUri())
		assert.equals("tests/TestData/MetaFly/metadata.db", db:getUri())
		assert.is_string(db:getCommand())

		local noteBoxes = testConfig["noteBoxes"]
		print("Starting scan of single note box with config: " .. vim.inspect(noteBoxes[1]))
		setUpController:scanNoteBox(noteBoxes[1])

		local noteBox = NoteBox.select({ name = "TestData" })
		assert.is_not_nil(noteBox, "Expected to find a NoteBox with name 'TestData' in the database")

		local numberOfNotes = Note.count({ idNoteBox = noteBox.id })
		assert.is_true(
			numberOfNotes == 8,
			"Expected 8 notes in note box " .. noteBox:getName() .. ", but found " .. numberOfNotes
		)

		local note = Note.getNoteWithId(noteBox:getId(), "240302011450")
		assert.is_not_nil(note, "Expected to find a note with id '240302011450' in the database")

		local numberOfMetaData = MetaDataToNote.count({ idNote = note:getId() })
		assert.is_true(
			numberOfMetaData == 4,
			"Expected 4 metadata entries for note with id '240302011450', but found " .. numberOfMetaData
		)

		local numberOfJsonData = JsonDataToNote.count({ idNote = note:getId() })
		assert.is_true(
			numberOfJsonData == 2,
			"Expected 2 jsondata entries for note with id '240302011450', but found " .. numberOfJsonData
		)

		local changedMetaData = {
			project = { "project one", "project two" },
			property = { "second value", "third value" },
			author = "Victor Hugo",
		}
		databaseController.updateMetaData(note, changedMetaData)

		local numberOfMetaData = MetaDataToNote.count({ idNote = note:getId() })
		assert.is_true(
			numberOfMetaData == 5,
			"Expected 5 metadata entries for note with id '240302011450', but found " .. numberOfMetaData
		)

		local numberOfJsonData = JsonDataToNote.count({ idNote = note:getId() })
		assert.is_true(
			numberOfJsonData == 3,
			"Expected 3 jsondata entries for note with id '240302011450', but found " .. numberOfJsonData
		)
	end)
end)
