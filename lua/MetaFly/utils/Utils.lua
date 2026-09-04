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

---Normalise values before storing them in sqlite so that text fields are
---always proper Lua strings and idNoteBox is a number.  This prevents
---sqlite.lua from raw-interpolating values that look like SQL expressions
---(e.g. "26.3-2(16.07-29.07)") instead of binding them as parameters.
---@param values table
---@param textFields table
---@param numberFields table
---@return table
function Utils.sanitiseValues(values, textFields, numberFields)
	local result = {}
	for k, v in pairs(values) do
		result[k] = v
	end
	for _, field in ipairs(numberFields) do
		if result[field] ~= nil then
			result[field] = tonumber(result[field])
		end
	end
	for _, field in ipairs(textFields) do
		if result[field] ~= nil then
			result[field] = tostring(result[field])
		end
	end
	return result
end

return Utils
