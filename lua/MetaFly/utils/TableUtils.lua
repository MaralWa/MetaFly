TableUtils = {}

---comment
---@param inTable table
---@param prefix string
---@param outTable table
function TableUtils.printTable(inTable, prefix, outTable)
	for k, v in pairs(inTable) do
		if type(v) ~= "table" then
			table.insert(outTable, prefix .. k .. " -> " .. v)
		else
			if type(v) == "table" then
				table.insert(outTable, k .. " table")
				TableUtils.printTable(v, prefix, outTable)
			end
		end
	end
end

---comment
---@param inTable table
---@return table
function TableUtils.convertToLines(inTable)
	local outTable = {}
	TableUtils.printTable(inTable, "  ", outTable)
	return outTable
end

return TableUtils
