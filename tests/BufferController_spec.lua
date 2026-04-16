local BufferValidator = require("MetaFly.view.BufferValidator")
local BufferController = require("MetaFly.controller.BufferController")

describe("MetaFly.controller.BufferController", function()
	describe("refreshViews", function()
		it("should be a function", function()
			assert.is_function(BufferController.refreshViews)
		end)

		it("should notify when buffer has no views", function()
			-- Create a scratch buffer with no view markers
			local bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_current_buf(bufnr)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
				"# A normal document",
				"",
				"No MetaFly views here.",
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
			assert.is_truthy(notified_msg:find("Keine Views"))
			assert.are.equal(vim.log.levels.INFO, notified_level)
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
end)
