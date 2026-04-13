local ViewFactory = require("MetaFly.view.ViewFactory")

ViewController = {
	viewStack = {},
	currentView = nil,
}

function ViewController.showView(viewName)
	if viewName == nil or viewName == "" then
		logger.error("MetaFly view: showView called with invalid viewName: " .. tostring(viewName))
		vim.notify("MetaFly view: showView called with invalid viewName: " .. tostring(viewName), vim.log.levels.ERROR)
		return
	end

	logger.info("MetaFly view: showView " .. viewName)
	vim.notify("MetaFly view: showView " .. viewName)

	local view = ViewFactory.readFromFile(viewName)
	if view == nil then
		logger.error("MetaFly view: Failed to load view from file: " .. viewName)
		vim.notify("MetaFly view: Failed to load view from file: " .. viewName, vim.log.levels.ERROR)
		return
	end

	local viewData = view:getViewData()
	if viewData == nil then
		logger.error("MetaFly view: Failed to get view data for view: " .. viewName)
		vim.notify("MetaFly view: Failed to get view data for view: " .. viewName, vim.log.levels.ERROR)
		return
	end

	local beginline = '<!-- MetaFlyViewBegin "' .. view.name .. '" -->'
	local endline = '<!-- MetaFlyViewEnd "' .. view.name .. '" -->'

	local viewWindow = require("MetaFly.view.SqlResultWindow"):new("MetaFly View: " .. view.name)
	viewWindow:setContent(viewData, beginline, endline)
	viewWindow:open()
end

return ViewController
