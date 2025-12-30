local loop = vim.loop

Utils = {}

Utils.isDirectoryReadable = function(path)
	local stat = loop.lfs.fs_stat(path)
	return stat and stat.type == "directory"
end

---Returns the basename of a path without its file extension.
---@param path string
---@return string
function Utils.getFileNameWithoutExtension(path)
	-- the file name from the path
	local name = path:match("([^/\\]+)$") or path

	-- in case of hidden files:
	-- if the name has no extension, return it as is
	if name:match("^%.[^%.]+$") then
		return name
	end

	-- remove the extension
	local noext = name:match("(.+)%.[^%.]+$") or name
	return noext
end

return Utils
