local BufferValidator = {}

local BEGIN_PATTERN = '^<!%-%- MetaFlyViewBegin "(.+)" %-%->$'
local END_PATTERN = '^<!%-%- MetaFlyViewEnd "(.+)" %-%->$'

--- Validates MetaFly view regions in a list of buffer lines.
--- Checks for missing begin/end markers and overlapping regions.
---
---@param lines string[] The lines of the buffer to validate
---@return boolean hasErrors true if errors were found, false otherwise
---@return table results If no errors: array of {begin, end} line number pairs.
---                       If errors: array of {line, message} error descriptions.
function BufferValidator.validate(lines)
	if lines == nil or #lines == 0 then
		return false, {}
	end

	local regions = {}
	local errors = {}
	local openRegion = nil -- { name = "viewName", beginLine = lineNumber }

	for i, line in ipairs(lines) do
		local beginName = line:match(BEGIN_PATTERN)
		local endName = line:match(END_PATTERN)

		if beginName and endName then
			-- A line cannot be both a begin and end marker with normal patterns,
			-- but handle gracefully
			table.insert(errors, { line = i, message = "Zeile ist gleichzeitig Anfangs- und Endmarkierung" })
		elseif beginName then
			if openRegion then
				table.insert(errors, {
					line = i,
					message = 'Überlappender Bereich: "'
						.. beginName
						.. '" beginnt, bevor "'
						.. openRegion.name
						.. '" (Zeile '
						.. openRegion.beginLine
						.. ") geschlossen wurde",
				})
			else
				openRegion = { name = beginName, beginLine = i }
			end
		elseif endName then
			if openRegion == nil then
				table.insert(errors, {
					line = i,
					message = 'Fehlende Anfangsmarkierung für "' .. endName .. '"',
				})
			elseif openRegion.name ~= endName then
				table.insert(errors, {
					line = i,
					message = 'Endmarkierung "'
						.. endName
						.. '" stimmt nicht mit Anfangsmarkierung "'
						.. openRegion.name
						.. '" (Zeile '
						.. openRegion.beginLine
						.. ") überein",
				})
				openRegion = nil
			else
				table.insert(regions, { beginLine = openRegion.beginLine, endLine = i })
				openRegion = nil
			end
		end
	end

	-- Check for unclosed region at end of buffer
	if openRegion then
		table.insert(errors, {
			line = openRegion.beginLine,
			message = 'Fehlende Endmarkierung für "' .. openRegion.name .. '"',
		})
	end

	if #errors > 0 then
		return true, errors
	end

	return false, regions
end

return BufferValidator
