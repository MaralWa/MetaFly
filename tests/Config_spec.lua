local uv = vim.loop

local Config = require("MetaFly.Config")

describe("MetaFly.Config", function()
	it("allows overriding config values", function()
		local config = Config:getInstance()
		config:setup()
		assert.equals("~/.config/metafly_database.db", config.database)
		assert.equals("~/.config/views/", config.views)
		assert.equals(0, #config.noteBoxes)
	end)

	it("does not modify the original config table", function()
		local opts = {
			logger = {
				level = "DEBUG",
				logFile = "tests/TestData/metafly.log",
			},
			database = "/Users/sarah/.config/metafly/metadata.db",
			views = "/Users/sarah/.config/metafly/views/",
			noteBoxes = {
				{
					name = "VimWiki",
					path = "/Users/sarah/Documents/vimwiki",
					maxdepth = 2,
					ignored = { "MetaFly", "Tagebuch", "Templater", "Templates" },
				},
			},
		}

		local config = Config:getInstance()
		config:setup(opts)
		assert.equals("/Users/sarah/.config/metafly/metadata.db", config.database)
		assert.equals("/Users/sarah/.config/metafly/views/", config.views)
		assert.equals(1, #config.noteBoxes)
		assert.equals("DEBUG", config.logger.level)
		assert.equals("tests/TestData/metafly.log", config.logger.logFile)
	end)
end)
