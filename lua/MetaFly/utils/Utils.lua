local loop = vim.loop

Utils = {}

logger = require("MetaFly.config"):getInstance():getLogger()

Utils.isDirectoryReadable = function(path)
	local stat = loop.lfs.fs_stat(path)
	return stat and stat.type == "directory"
end

---@param path string
---@return boolean
Utils.isFileReadable = function(path)
	local stat = loop.fs_stat(path)
	return stat ~= nil and stat.type == "file"
end

--- Sucht ein File im Verzeichnis anhand des Basisnamens (ohne Endung).
--- Probiert alle übergebenen Endungen der Reihe nach.
---@param dir string
---@param basename string  z.B. "myView"
---@param extensions table  z.B. { ".yml", ".yaml" }
---@return string|nil  vollständiger Pfad wenn gefunden, sonst nil
Utils.findFileByBasename = function(dir, basename, extensions)
	logger.debug(
		"Utils.findFileByBasename: Searching for '"
			.. basename
			.. "' in '"
			.. dir
			.. "' with extensions: "
			.. table.concat(extensions, ", ")
	)
	if dir:sub(-1) ~= "/" then
		dir = dir .. "/"
	end
	for _, ext in ipairs(extensions) do
		local fullPath = vim.fn.expand(dir .. basename .. ext)
		if vim.fn.filereadable(fullPath) == 1 then
			return fullPath
		end
	end
	return nil
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
