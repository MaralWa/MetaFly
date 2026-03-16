local Logger = require("MetaFly.utils.Logger")

describe("MetaFly.Logger", function()
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

	it("logs messages at different levels", function()
		local config = require("MetaFly.Config"):getInstance()
		config:setup(opts)
		print("Config after setup:")
		print(vim.inspect(config))
		print()

		local logger = Logger:getInstance()
		assert.equals("DEBUG", logger.level)
		assert.equals("tests/TestData/metafly.log", logger.logFile)
	end)
end)
