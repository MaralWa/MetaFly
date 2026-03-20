describe("MetaFly.Logger", function()
	local log_file = "tests/TestData/metafly.log"
	local opts = {
		logger = {
			level = "DEBUG",
			logFile = log_file,
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

	before_each(function()
		-- Reset singletons so each test starts fresh
		package.loaded["MetaFly.config"] = nil
		package.loaded["MetaFly.utils.Logger"] = nil

		-- Ensure the TestData directory exists and the log file is empty
		vim.fn.mkdir(vim.fn.fnamemodify(log_file, ":h"), "p")
		local f = io.open(log_file, "w")
		if f then
			f:close()
		end
	end)

	after_each(function()
		os.remove(log_file)
	end)

	it("creates the logger instance correctly", function()
		require("MetaFly.config"):getInstance():setup(opts)
		local Logger = require("MetaFly.utils.Logger")
		local logger = Logger:getInstance()

		assert.is_not_nil(logger)
		assert.is_not_nil(logger.logger)
	end)

	it("writes log messages to the configured log file", function()
		require("MetaFly.config"):getInstance():setup(opts)
		local Logger = require("MetaFly.utils.Logger")
		local logger = Logger:getInstance()

		logger:debug("test info message")

		local f = io.open(log_file, "r")
		assert.is_not_nil(f)
		local content = f:read("*a")
		f:close()

		assert.is_truthy(#content > 0)
		assert.is_truthy(content:find("INFO") ~= nil)
		assert.is_truthy(content:find("test info message") ~= nil)
	end)
end)
