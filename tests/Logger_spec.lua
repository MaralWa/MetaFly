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
		local config = require("MetaFly.config"):getInstance()
		config:setup(opts)
		print("Config after setup:")
		print(vim.inspect(config))
		print()

		local logger = Logger:getInstance()

		logger:debug("This is a debug message")
		logger:info("This is an info message")
		logger:warn("This is a warning message")
		logger:error("This is an error message")
	end)
end)
