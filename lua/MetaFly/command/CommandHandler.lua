local logger = require("MetaFly.utils.Logger")
local config = require("MetaFly.config"):getInstance()

local CommandHandler = {}

function CommandHandler.execute(subcommand, ...)
	-- Handle case where arguments might be passed as a table
	local args
	if type(subcommand) == "table" then
		-- Arguments were passed as a single table
		args = subcommand
		subcommand = args[1]
		table.remove(args, 1)
	else
		-- Arguments were passed individually
		args = { ... }
	end
	if subcommand == "Picker" then
		CommandHandler.executePicker(unpack(args))
	elseif subcommand == "Notes" then
		CommandHandler.executeNotes()
	elseif subcommand == "Uri" then
		CommandHandler.executeUri()
	else
		logger.error("Unknown MetaFly subcommand: " .. tostring(subcommand))
		vim.notify("Unknown MetaFly subcommand: " .. tostring(subcommand), vim.log.levels.ERROR)
	end
end

function CommandHandler.executePicker(fileNameOrBase)
	local NotePicker = require("MetaFly.picker.NotePicker")

	if fileNameOrBase == nil then
		NotePicker.notesView()
	else
		local isFullPath = fileNameOrBase:match("[/\\~]") ~= nil

		local fullPath
		if isFullPath then
			fullPath = vim.fn.expand(fileNameOrBase)
		else
			local viewsPath = config.views
			if viewsPath:sub(-1) ~= "/" then
				viewsPath = viewsPath .. "/"
			end

			local fileName = fileNameOrBase
			if not fileName:match("%.ya?ml$") then
				fileName = fileName .. ".yml"
			end

			fullPath = vim.fn.expand(viewsPath .. fileName)
		end

		logger.info("Loading picker from: " .. fullPath)
		NotePicker.notesView(fullPath)
	end
end

function CommandHandler.executeNotes()
	local NotePicker = require("MetaFly.picker.NotePicker")
	NotePicker.notesView()
end

function CommandHandler.executeUri()
	local database = require("MetaFly.model.database"):getInstance()
	database:printUri()
end

function CommandHandler.executeSqlResult(...)
	local SqlResultWindow = require("MetaFly.view.SqlResultWindow")
	local database = require("MetaFly.model.database"):getInstance()
	SqlResultWindow.displaySqlResult(database, ...)
end

return CommandHandler
