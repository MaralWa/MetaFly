local lyaml = require("lyaml")
local MetaFlyView = require("MetaFly.model.MetaFlyView")
local Utils = require("MetaFly.utils.Utils")

local ViewFactory = {}

local logger = require("MetaFly.config"):getInstance():getLogger("ViewFactory")

function ViewFactory.resolveFileName(viewName)
	logger.info("Resolving file name for view: " .. viewName)
	local config = require("MetaFly.config"):getInstance()
	local viewDir = config:getViewsDirectory()
	if viewDir == nil then
		logger.error("View directory is null")
		return nil
	end
	logger.info("View directory: " .. tostring(viewDir))
	return Utils.findFileByBasename(viewDir, viewName, { ".yml", ".yaml" })
end

---@param viewName string
---@return MetaFlyView|nil
function ViewFactory.readFromFile(viewName)
	local create = {}

	create["Picker"] = function(values)
		logger.debug("Creating picker view from values: " .. vim.inspect(values))
		return require("MetaFly.model.PickerView"):new(values)
	end

	logger.info("Resolving file name for view: " .. viewName)
	local fileName = ViewFactory.resolveFileName(viewName)
	if fileName == nil then
		logger.error("No view file found for view name: " .. viewName)
		return nil
	end
	logger.info("Reading view from file: " .. fileName)
	local viewFile = io.open(fileName, "r")
	if viewFile == nil then
		logger.error("viewFile ist null")
		return nil
	end
	local viewYaml = viewFile:read("*all")
	viewFile:close()
	local viewData = lyaml.load(viewYaml)

	if viewData == nil then
		logger.error("viewData ist null")
		return nil
	end
	local viewType = viewData["type"]
	if create[viewType] == nil then
		logger.error("Unknown view type: " .. tostring(viewType))
		return nil
	end

	logger.info("Creating view of type: " .. viewType)
	return create[viewType](viewData)
end

function ViewFactory.createView(viewType, values)
	if viewType == "PickerView" then
		local PickerView = {}
		PickerView.__index = PickerView

		setmetatable(PickerView, {
			__index = MetaFlyView, -- Inherit from MetaFlyView
		})

		function PickerView:new(values)
			local newObject = MetaFlyView.new(self, values)
			setmetatable(newObject, self)
			newObject.columns = { "Note.title", "NoteBox.path || '/' || Note.fileName" }
			newObject.from = "Note, NoteBox"
			newObject.sqlMode = "csv"
			table.insert(newObject.where, "Note.idNoteBox = NoteBox.id")
			return newObject
		end

		return PickerView:new(values)
	end

	-- Add more view types as needed

	return nil
end

return ViewFactory
