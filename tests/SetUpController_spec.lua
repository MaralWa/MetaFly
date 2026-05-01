-- Setup: Füge das aktuelle Verzeichnis und sqlite.lua zum runtimepath hinzu
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local data_path = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data_path .. "/lazy/sqlite.lua")

local uv = vim.loop

Database = require("MetaFly.model.database")
Config = require("MetaFly.config")

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
	local db = require("MetaFly.model.database"):getInstance()
	logger.info("MetaFly Database initialized at: " .. db:getUri())

	-- Create the SetUpController instance that performs the actual scanning
	local setUpController = require("MetaFly.controller.SetUpController"):new()
	it("Scanning of single note", function()
		assert.is_string(db:getUri())
		assert.equals("tests/TestData/MetaFly/metadata.db", db:getUri())
		assert.is_string(db:getCommand())

		local noteBoxes = testConfig["noteBoxes"]
		print("Starting scan of single note box with config: " .. vim.inspect(noteBoxes[1]))
		setUpController:scanNoteBox(noteBoxes[1])

		local numberOfNotes = db:getQueryResultAsTable("SELECT COUNT(*) AS count FROM Note")
		assert.is_true(
			numberOfNotes[1]["count"] == 8,
			"Expected 8 notes in the database, but found " .. numberOfNotes[1]["count"]
		)
	end)
end)
