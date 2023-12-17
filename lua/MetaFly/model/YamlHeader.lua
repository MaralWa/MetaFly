local lyaml = require("lyaml")

---@class YamlHeader
---@field private header table
local YamlHeader = {
	header, --
}

---@param key string
function YamlHeader:geValue(key)
	return self.header[key]
end

---@param bufferNumber number
function YamlHeader:getFromBuffer(bufferNumber)
	local lineNumber = 1
	local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
	local viewContentStr = ""
	local viewContent = {}
	if line == "---" then
		local yamlHeaderStr = line
		local endOfYaml = false
		while not endOfYaml do
			lineNumber = lineNumber + 1
			line = vim.fn.getbufoneline(bufferNumber, lineNumber)
			yamlHeaderStr = yamlHeaderStr .. "\n" .. line
			if line == "---" then
				endOfYaml = true
			end
		end
	end

	local newObject = setmetatable({}, self)
	self.__index = self
	newObject.header = lyaml.load(yamlHeaderStr)

	return newObject
end

function YamlHeader.update_view()
	local lineNumber = 1
	local bufferNumber = vim.fn.bufnr("%")
	-- local bufferNumber = 11
	local line = vim.fn.getbufoneline(bufferNumber, lineNumber)
	--
	local viewContentStr = ""
	local viewContent = {}
	if line == "---" then
		viewContent[lineNumber] = line
		yamlHeaderStr = line
		local endOfYaml = false
		while not endOfYaml do
			lineNumber = lineNumber + 1
			line = vim.fn.getbufoneline(bufferNumber, lineNumber)
			viewContent[lineNumber] = line
			yamlHeaderStr = yamlHeaderStr .. "\n" .. line
			if line == "---" then
				endOfYaml = true
			end
		end
	end
end

return YamlHeader
