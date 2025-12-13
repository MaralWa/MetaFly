-- luacheck: globals vim

local loop = require(vim.loop)

M = {}

M.isDirectoryReadable = function(path)
	local stat = loop.fs_stat(path)
	return stat and stat.type == "directory"
end

return M
