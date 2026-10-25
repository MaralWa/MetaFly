describe("lifecycle", function()
	local lifecycle

	before_each(function()
		package.loaded["MetaFly.lifecycle"] = nil
		lifecycle = require("MetaFly.lifecycle")
	end)

	it("is not shutting down initially", function()
		assert.is_false(lifecycle.is_shutting_down())
	end)

	it("shutdown is idempotent and closes registered handles", function()
		local stopped, closed = 0, 0
		lifecycle.register_timer({
			stop = function() stopped = stopped + 1 end,
			close = function() closed = closed + 1 end,
		})
		lifecycle.shutdown()
		lifecycle.shutdown()
		assert.is_true(lifecycle.is_shutting_down())
		assert.are.equal(1, stopped)
		assert.are.equal(1, closed)
	end)

	it("does not throw when a handle errors", function()
		lifecycle.register_handle({ close = function() error("boom") end })
		assert.has_no.errors(lifecycle.shutdown)
	end)
end)

describe("AsyncScanner", function()
	it("does not scan or schedule during shutdown", function()
		package.loaded["MetaFly.lifecycle"] = nil
		local lifecycle = require("MetaFly.lifecycle")
		package.loaded["MetaFly.controller.AsyncScanner"] = nil
		local scanner = require("MetaFly.controller.AsyncScanner")
		lifecycle.shutdown()
		local scheduled = 0
		local orig = vim.schedule
		vim.schedule = function() scheduled = scheduled + 1 end
		local ok, err = pcall(scanner.scanInBackground, { noteBoxes = { { name = "a" } } })
		vim.schedule = orig
		assert.is_true(ok, err)
		assert.are.equal(0, scheduled)
	end)
end)
