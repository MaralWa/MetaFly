local ActionCommandHandler = require("MetaFly.command.ActionCommandHandler")

describe("MetaFly.command.ActionCommandHandler", function()
	-- -----------------------------------------------------------------------
	-- Basic structure checks
	-- -----------------------------------------------------------------------

	it("should export an ACTIONS table with the six supported actions", function()
		assert.is_table(ActionCommandHandler.ACTIONS)
		local lookup = {}
		for _, a in ipairs(ActionCommandHandler.ACTIONS) do
			lookup[a] = true
		end
		local expected = { "open", "view", "select", "query", "search", "explore" }
		assert.are.equal(#expected, #ActionCommandHandler.ACTIONS)
		for _, action in ipairs(expected) do
			assert.is_true(lookup[action], "Expected action '" .. action .. "' to be present")
		end
	end)

	it("should have an execute function", function()
		assert.is_function(ActionCommandHandler.execute)
	end)

	it("should have an executeAction function", function()
		assert.is_function(ActionCommandHandler.executeAction)
	end)

	it("should have a promptAction function", function()
		assert.is_function(ActionCommandHandler.promptAction)
	end)

	-- -----------------------------------------------------------------------
	-- Individual action handler functions
	-- -----------------------------------------------------------------------

	it("should have executeOpen function", function()
		assert.is_function(ActionCommandHandler.executeOpen)
	end)

	it("should have executeView function", function()
		assert.is_function(ActionCommandHandler.executeView)
	end)

	it("should have executeSelect function", function()
		assert.is_function(ActionCommandHandler.executeSelect)
	end)

	it("should have executeQuery function", function()
		assert.is_function(ActionCommandHandler.executeQuery)
	end)

	it("should have executeSearch function", function()
		assert.is_function(ActionCommandHandler.executeSearch)
	end)

	it("should have executeExplore function", function()
		assert.is_function(ActionCommandHandler.executeExplore)
	end)

	-- -----------------------------------------------------------------------
	-- Dispatch behaviour
	-- -----------------------------------------------------------------------

	it("should dispatch to executeOpen when action is 'open'", function()
		ActionCommandHandler.execute("open", "some/path")
		local lastAction = ActionCommandHandler.lastAction()
		assert.are.equal("open with args: some/path", lastAction)
	end)

	it("should dispatch to executeSearch when action is 'search'", function()
		ActionCommandHandler.execute("search", "keyword")
		local lastAction = ActionCommandHandler.lastAction()
		assert.are.equal("search with args: keyword", lastAction)
	end)

	it("should dispatch to promptAction when no action is given", function()
		local prompt_called = false
		local original = ActionCommandHandler.promptAction
		ActionCommandHandler.promptAction = function(_args)
			prompt_called = true
		end

		ActionCommandHandler.execute(nil, nil)

		ActionCommandHandler.promptAction = original
		assert.is_true(prompt_called)
	end)

	it("should dispatch to promptAction when action is an empty string", function()
		local prompt_called = false
		local original = ActionCommandHandler.promptAction
		ActionCommandHandler.promptAction = function(_args)
			prompt_called = true
		end

		ActionCommandHandler.execute("", nil)

		ActionCommandHandler.promptAction = original
		assert.is_true(prompt_called)
	end)

	it("should notify on unknown action", function()
		local notify_called = false
		local original_notify = vim.notify
		vim.notify = function(_msg, _level)
			notify_called = true
		end

		ActionCommandHandler.executeAction("unknownAction", nil)

		vim.notify = original_notify
		assert.is_true(notify_called)
	end)
end)
