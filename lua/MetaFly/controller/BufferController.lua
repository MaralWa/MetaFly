local YamlHeader = require("MetaFly.model.YamlHeader")
local NoteBox = require("MetaFly.model.NoteBox")
local BufferValidator = require("MetaFly.view.BufferValidator")
local ViewFactory = require("MetaFly.view.ViewFactory")
local DatabaseController = require("MetaFly.controller.DatabaseController")
local config = require("MetaFly.config"):getInstance()
local logger = config:getLogger("BufferController")

local BufferController = {}

---@param bufferNumber number number of the buffer to update
function BufferController.updateMetadata(bufferNumber)
	local bufferName = vim.fn.bufname(bufferNumber)
	if bufferName == nil or bufferName == "" then
		logger.debug("No file name for buffer " .. bufferNumber)
		return
	end

	local noteBoxConfig = BufferController.getNoteBoxOfFile(bufferName)
	if noteBoxConfig == nil then
		logger.debug("No NoteBox found for buffer " .. bufferName)
		return
	end

	local noteBox = NoteBox.selectOrInsertNoteBox(noteBoxConfig)
	if noteBox == nil then
		logger.error("Could not get NoteBox from database for: " .. noteBoxConfig.name)
		return
	end

	local yamlHeader, errorMsg = YamlHeader:getFromBuffer(bufferNumber)
	if errorMsg ~= nil then
		logger.debug("Cannot read YAML header from buffer " .. bufferNumber .. ": " .. errorMsg)
		return
	end

	logger.debug("Header lines for buffer " .. bufferNumber .. ": " .. vim.inspect(yamlHeader:getHeaderLines()))
	DatabaseController.updateNote(bufferName, noteBox, yamlHeader)
end

---@param fileName string of the buffer whose
---@return table or nil if no NoteBox is found for the given fileName
function BufferController.getNoteBoxOfFile(fileName)
	local noteBox = nil
	for _, noteBoxConfig in ipairs(config.noteBoxes) do
		local noteBoxPath = noteBoxConfig.path
		if not vim.startswith(fileName, noteBoxPath) then
			goto next_notebox
		end

		local length = string.len(noteBoxPath)
		local relativeFileName = string.sub(fileName, length + 1, -1)

		local isIgnored = false
		for _, ignored in ipairs(noteBoxConfig.ignored) do
			if vim.startswith(relativeFileName, ignored) then
				isIgnored = true
			end
		end

		if isIgnored then
			goto next_notebox
		end

		local _, noOfDirs = string.gsub(relativeFileName, "/", "")
		if noOfDirs - 1 <= noteBoxConfig.maxdepth then
			noteBox = noteBoxConfig
			break
		end

		::next_notebox::
	end

	return noteBox
end

--- Refreshes all MetaFly view regions in the current buffer.
--- Uses BufferValidator to find view regions, then replaces their co , ,ntent
--- with the latest data from the database.
function BufferController.refreshViews()
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local hasErrors, results = BufferValidator.validate(lines)

	if hasErrors then
		for _, err in ipairs(results) do
			logger.error("BufferValidator error at line " .. err.line .. ": " .. err.message)
		end
		vim.notify("MetaFly refresh: Buffer enthält fehlerhafte View-Markierungen.", vim.log.levels.ERROR)
		return
	end

	if #results == 0 then
		vim.notify("MetaFly refresh: Keine Views im aktuellen Buffer gefunden.", vim.log.levels.INFO)
		return
	end

	-- Process regions from bottom to top so that line number changes
	-- from earlier replacements do not affect later regions.
	for i = #results, 1, -1 do
		local region = results[i]
		local view = ViewFactory.readFromFile(region.name)
		if view == nil then
			vim.notify(
				'MetaFly refresh: View "' .. region.name .. '" konnte nicht geladen werden.',
				vim.log.levels.WARN
			)
		else
			local viewData = view:getViewData()
			if viewData == nil then
				vim.notify(
					'MetaFly refresh: Keine Daten für View "' .. region.name .. '" erhalten.',
					vim.log.levels.WARN
				)
			else
				-- Replace lines between begin and end markers (exclusive of markers).
				-- BufferValidator returns 1-based line numbers.
				-- nvim_buf_set_lines uses 0-based start (inclusive) and end (exclusive).
				-- beginLine (1-based) conveniently equals the 0-based index of the next line,
				-- i.e. the first content line after the begin marker.
				-- endLine - 1 (1-based → 0-based) is the exclusive end, stopping before the end marker.
				local startIdx = region.beginLine
				local endIdx = region.endLine - 1
				vim.api.nvim_buf_set_lines(bufnr, startIdx, endIdx, false, viewData)
				logger.info('Refreshed view "' .. region.name .. '"')
			end
		end
	end

	vim.notify("MetaFly refresh: Views wurden aktualisiert.", vim.log.levels.INFO)
end

return BufferController
