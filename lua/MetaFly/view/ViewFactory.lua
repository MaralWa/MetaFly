local lyaml = require("lyaml")
local MetaFlyView = require("MetaFly.model.MetaFlyView")

local ViewFactory = {}

local logger = require("MetaFly.config"):getInstance():getLogger("ViewFactory")

---@param fileName string
---@return MetaFlyView|nil
function ViewFactory.readFromFile(fileName)
	local create = {

		Picker = function(values)
			vim.notify("Creating picker view from file: " .. fileName, vim.log.levels.ERROR)
			return require("MetaFly.model.PickerView"):new(values)
		end,
	}

	logger:info("Reading view from file: " .. fileName)
	vim.notify("Reading view from file: " .. fileName)
	local viewFile = io.open(fileName, "r")
	if viewFile == nil then
		logger:info("viewFile ist null")
		vim.notify("viewFile ist null")
		return nil
	end
	local viewYaml = viewFile:read("*all")
	viewFile:close()
	local viewData = lyaml.load(viewYaml)

	if viewData == nil then
		logger:info("viewData ist null")
		vim.notify("viewData ist null")
		return nil
	end
	local viewType = viewData["type"]
	if create[viewType] == nil then
		logger:info("Unknown view type: " .. tostring(viewType))
		vim.notify("Unknown view type: " .. tostring(viewType))
		return nil
	end

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
