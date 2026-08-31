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

	it("should have a URI and command", function()
		assert.is_string(db:getUri())
		assert.equals("tests/TestData/MetaFly/metadata.db", db:getUri())
		assert.is_string(db:getCommand())
	end)

	it("should initialize the database connection", function()
		assert.is_not_nil(db.DB)
	end)

	it("should set and get URI correctly", function()
		local testUri = "~/.config/metafly_database.db"
		db:setUri(testUri)
		assert.equals(testUri, db:getUri())
	end)

	it("should set and get command correctly", function()
		local testCommand = "sqlite3 test.db"
		db:setCommand(testCommand)
		assert.equals(testCommand, db:getCommand())
		local note = db:select("select * from Note limit 1")
		assert.is_table(note)
		print(vim.inspect(note))
	end)
end)
