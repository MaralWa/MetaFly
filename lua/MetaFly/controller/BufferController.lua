local YamlHeader = require("MetaFly.model.YamlHeader")
local MetaFly = require("MetaFly.")

local BufferController = {}

---@param bufferNumber number of the buffer whose
function BufferController:updateMetadata(bufferNumber)
	local bufferInfo = vim.fn.bufinfo(bufferNumber)
	local bufferName = vim.fn.bufname(bufferNumber)
	local metaData = YamlHeader:getFromBuffer(bufferNumber)
	local fileOfBuffer = vim.fn.GetFile(bufferNumber)
end

return BufferController
