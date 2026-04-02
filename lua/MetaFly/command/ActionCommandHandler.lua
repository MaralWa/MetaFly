local config = require("MetaFly.config"):getInstance()
local logger = config:getLogger()

-- ActionCommandHandler provides an alternative command handler for the "MetaFly"
-- command that supports a set of well-defined actions (open, view, select, query,
-- search, explore).  When no action is supplied the user is prompted interactively
-- to choose one.  Any additional arguments for an action are forwarded as a single
-- string so that each action handler can parse them freely.

local ActionCommandHandler = {}

local lastAction = nil

ActionCommandHandler.lastAction = function()
	return lastAction
end

-- The ordered list of supported actions.
ActionCommandHandler.ACTIONS = { "open", "view", "select", "query", "search", "explore" }

-- Dispatch table mapping action names to their handler functions.
-- Populated after the handler functions are defined below.
local actionDispatch = {}

-- Execute the given action with an optional argument string.
-- Uses the actionDispatch table for O(1) lookup instead of an if-elseif chain.
-- @param action  string  One of the supported action names (case-sensitive).
-- @param args    string  Optional free-form argument string passed to the action.
function ActionCommandHandler.executeAction(action, args)
	local handler = actionDispatch[action]
	if handler then
		lastAction = action .. (args and (" with args: " .. args) or "")
		handler(args)
	else
		lastAction = "Unknown MetaFly action: " .. tostring(action)
		logger.error(lastAction)
		vim.notify(lastAction, vim.log.levels.ERROR)
	end
end

-- Main entry point called by the :MetaFly command.
-- @param action  string|nil  The action to perform. When nil the user is prompted.
-- @param args    string|nil  Optional free-form argument string for the action.
function ActionCommandHandler.execute(action, args)
	if action == nil or action == "" then
		-- No action supplied – ask the user which one to run.
		ActionCommandHandler.promptAction(args)
	end
	ActionCommandHandler.executeAction(action, args)
end

-- Show an interactive picker so the user can choose an action at runtime.
-- Once selected the chosen action is executed with the original args string.
-- @param args  string|nil  Optional argument string to forward to the chosen action.
function ActionCommandHandler.promptAction(args)
	vim.ui.select(ActionCommandHandler.ACTIONS, {
		prompt = "MetaFly – select action:",
	}, function(choice)
		if choice ~= nil then
			ActionCommandHandler.executeAction(choice, args)
		end
	end)
end

-- ---------------------------------------------------------------------------
-- Action implementations
-- The bodies below are intentionally minimal stubs.  Detailed behaviour for
-- each action can be filled in later without touching the dispatch logic.
-- ---------------------------------------------------------------------------

-- Open a note or resource identified by args.
-- @param args  string|nil  Free-form argument string (e.g. a file path or note id).
function ActionCommandHandler.executeOpen(args)
	logger.info("MetaFly action: open" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly open: " .. tostring(args), vim.log.levels.INFO)
end

-- Display a view, optionally specified by args.
-- @param args  string|nil  Free-form argument string (e.g. a view name or path).
function ActionCommandHandler.executeView(args)
	logger.info("MetaFly action: view" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly view: " .. tostring(args), vim.log.levels.INFO)
end

-- Select an item interactively, with optional filter/scope in args.
-- @param args  string|nil  Free-form argument string passed to the selection UI.
function ActionCommandHandler.executeSelect(args)
	logger.info("MetaFly action: select" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly select: " .. tostring(args), vim.log.levels.INFO)
end

-- Run a query against the note database.
-- @param args  string|nil  Free-form SQL or query expression.
function ActionCommandHandler.executeQuery(args)
	logger.info("MetaFly action: query" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly query: " .. tostring(args), vim.log.levels.INFO)
end

-- Search notes by keyword or pattern given in args.
-- @param args  string|nil  Free-form search string or pattern.
function ActionCommandHandler.executeSearch(args)
	logger.info("MetaFly action: search" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly search: " .. tostring(args), vim.log.levels.INFO)
end

-- Explore the note collection, optionally scoped by args.
-- @param args  string|nil  Free-form scope or starting path.
function ActionCommandHandler.executeExplore(args)
	logger.info("MetaFly action: explore" .. (args and (" args=" .. args) or ""))
	vim.notify("MetaFly explore: " .. tostring(args), vim.log.levels.INFO)
end

-- Wire up the dispatch table so executeAction can resolve handlers by name.
actionDispatch["open"] = ActionCommandHandler.executeOpen
actionDispatch["view"] = ActionCommandHandler.executeView
actionDispatch["select"] = ActionCommandHandler.executeSelect
actionDispatch["query"] = ActionCommandHandler.executeQuery
actionDispatch["search"] = ActionCommandHandler.executeSearch
actionDispatch["explore"] = ActionCommandHandler.executeExplore

return ActionCommandHandler
