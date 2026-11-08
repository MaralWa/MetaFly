local BufferValidator = require("MetaFly.view.BufferValidator")
local BufferController = require("MetaFly.controller.BufferController")
local ViewFactory = require("MetaFly.view.ViewFactory")
local Config = require("MetaFly.config"):getInstance()

describe("MetaFly.controller.BufferController", function()
	describe("refreshViews", function()
		it("should be a function", function()
			assert.is_function(BufferController.refreshViews)
		end)

		it("should not notify when buffer has no views", function()
			-- Create a scratch buffer with no view markers
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				"# A normal document",
				"",
				"No MetaFly views here.",
			})

			local notifications = {}
			local original_notify = vim.notify
			vim.notify = function(msg, level)
				table.insert(notifications, { msg, level })
			end

			BufferController.refreshViews()
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
			BufferController.refreshViews()

			vim.notify = original_notify
			vim.api.nvim_buf_delete(bufnr, { force = true })

			assert.are.same({}, notifications)
		end)

		it("should refresh valid view regions", function()
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				"# Document",
				'<!-- MetaFlyViewBegin "testview" -->',
				"old data",
				'<!-- MetaFlyViewEnd "testview" -->',
			})

			local original_read = ViewFactory.readFromFile
			local original_notify = vim.notify
			local loaded_name
			ViewFactory.readFromFile = function(name)
				loaded_name = name
				return { getViewData = function() return { "new data", "more data" } end }
			end
			vim.notify = function() end

			BufferController.refreshViews()
			local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

			ViewFactory.readFromFile = original_read
			vim.notify = original_notify
			vim.api.nvim_buf_delete(bufnr, { force = true })

			assert.are.equal("testview", loaded_name)
			assert.are.same({
				"# Document",
				'<!-- MetaFlyViewBegin "testview" -->',
				"new data",
				"more data",
				'<!-- MetaFlyViewEnd "testview" -->',
			}, lines)
		end)

		it("should preserve warnings for missing views and view data", function()
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				'<!-- MetaFlyViewBegin "testview" -->',
				"old data",
				'<!-- MetaFlyViewEnd "testview" -->',
			})

			local original_read = ViewFactory.readFromFile
			local original_notify = vim.notify
			local notifications = {}
			vim.notify = function(msg, level)
				table.insert(notifications, { msg, level })
			end
			ViewFactory.readFromFile = function() return nil end
			BufferController.refreshViews()
			ViewFactory.readFromFile = function()
				return { getViewData = function() return nil end }
			end
			BufferController.refreshViews()

			ViewFactory.readFromFile = original_read
			vim.notify = original_notify
			vim.api.nvim_buf_delete(bufnr, { force = true })

			assert.is_truthy(notifications[1][1]:find("konnte nicht geladen werden", 1, true))
			assert.are.equal(vim.log.levels.WARN, notifications[1][2])
			assert.is_truthy(notifications[3][1]:find("Keine Daten", 1, true))
			assert.are.equal(vim.log.levels.WARN, notifications[3][2])
		end)

		it("should notify error when buffer has validation errors", function()
			-- Create a scratch buffer with a missing end marker
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				'<!-- MetaFlyViewBegin "broken" -->',
				"some content",
				-- missing end marker
			})

			local notified_msg = nil
			local notified_level = nil
			local original_notify = vim.notify
			vim.notify = function(msg, level)
				notified_msg = msg
				notified_level = level
			end

			BufferController.refreshViews()

			vim.notify = original_notify
			vim.api.nvim_buf_delete(bufnr, { force = true })

			assert.is_truthy(notified_msg)
			assert.is_truthy(notified_msg:find("fehlerhafte"))
			assert.are.equal(vim.log.levels.ERROR, notified_level)
		end)

		describe("automatic refresh", function()
			it("should refresh only Markdown filenames on BufEnter", function()
				local original_refresh = BufferController.refreshViews
				local calls = 0
				BufferController.refreshViews = function() calls = calls + 1 end
				vim.cmd("source " .. vim.fn.fnameescape(vim.fn.getcwd() .. "/plugin/MetaFly.vim"))

				vim.cmd("doautocmd <nomodeline> BufEnter note.md")
				vim.cmd("doautocmd <nomodeline> BufEnter note.markdown")
				vim.cmd("doautocmd <nomodeline> BufEnter note.txt")
				vim.cmd("doautocmd <nomodeline> BufEnter note.lua")

				BufferController.refreshViews = original_refresh
				vim.cmd("augroup MetaFlyRefreshViews | autocmd! | augroup END")
				vim.cmd("augroup MetaFlyBufWrite | autocmd! | augroup END")
				vim.g.loaded_metafly = nil
				vim.cmd("delcommand MetaFly")
				assert.are.equal(2, calls)
			end)
		end)

		it("should use BufferValidator to detect valid regions", function()
			-- Verify that BufferValidator correctly identifies a valid region
			-- which is the prerequisite for refreshViews to work
			local lines = {
				"# My Document",
				'<!-- MetaFlyViewBegin "testview" -->',
				"old data line 1",
				"old data line 2",
				'<!-- MetaFlyViewEnd "testview" -->',
				"# Footer",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_false(hasErrors)
			assert.are.equal(1, #results)
			assert.are.equal("testview", results[1].name)
			assert.are.equal(2, results[1].beginLine)
			assert.are.equal(5, results[1].endLine)
		end)
	end)

	describe("getNoteBoxOfFile", function()
		it("should return the name of the note box of buffer", function()
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
						path = "/home/user/tests/TestData",
						maxdepth = 3,
						ignored = { "MetaFly", "ignored", "Views" },
					},
					{
						name = "SecondNoteBox",
						path = "/home/user/noteBoxes/SecondNoteBox",
						maxdepth = 2,
						ignored = { "attachments", "diary", "Views" },
					},
				},
			}

			local config = Config:getInstance()
			config:setOptions(testConfig)

			local noteBox = BufferController.getNoteBoxOfFile("/home/user/tests/TestData/someBuffer.txt")
			assert.is_true(
				noteBox.name == "TestData",
				"Expected note box name to be 'TestData', got: " .. tostring(config.name)
			)

			noteBox = BufferController.getNoteBoxOfFile("/home/user/tests/TestData/Diary/year/month/someBuffer.txt")
			assert.is_true(
				noteBox.name == "TestData",
				"Expected note box name to be 'TestData', got: " .. tostring(config.name)
			)

			noteBox =
				BufferController.getNoteBoxOfFile("/home/user/noteBoxes/SecondNoteBox/diary/year/month/someBuffer.txt")
			assert.is_true(noteBox == nil, "Expected note box to be nil, got: " .. tostring(config.name))
		end)
	end)

	describe("updateMetadata", function()
		it("should be a function", function()
			assert.is_function(BufferController.updateMetadata)
		end)

		it("should return early for a buffer with no file name", function()
			-- Use a scratch buffer (no file name associated)
			local bufnr = vim.api.nvim_create_buf(false, true)
			-- updateMetadata should not error for nameless buffers
			assert.has_no.errors(function()
				BufferController.updateMetadata(bufnr)
			end)
			vim.api.nvim_buf_delete(bufnr, { force = true })
		end)

		it("should return early for a buffer whose file is not in a configured NoteBox", function()
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
						path = "/some/notebox/path",
						maxdepth = 3,
						ignored = {},
					},
				},
			}
			local config = Config:getInstance()
			config:setOptions(testConfig)

			-- Create a buffer with a name outside the configured NoteBox
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(bufnr, "/outside/notebox/file.md")

			-- Should return early without error
			assert.has_no.errors(function()
				BufferController.updateMetadata(bufnr)
			end)

			vim.api.nvim_buf_delete(bufnr, { force = true })
		end)
	end)
end)
