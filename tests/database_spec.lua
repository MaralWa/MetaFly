-- Setup: Füge das aktuelle Verzeichnis und sqlite.lua zum runtimepath hinzu
vim.opt.runtimepath:prepend(vim.fn.getcwd())
local data_path = vim.fn.stdpath("data")
vim.opt.runtimepath:append(data_path .. "/lazy/sqlite.lua")

local uv = vim.loop

Database = require("MetaFly.model.database")
Config = require("MetaFly.config")

describe("Database", function()
	local db

	before_each(function()
		Config:getInstance():setup({})
		db = Database:getInstance()
	end)

	it("should have a URI and command", function()
		assert.is_string(db:getUri())
		assert.equals("~/.config/metafly_database.db", db:getUri())
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
	end)
end)
