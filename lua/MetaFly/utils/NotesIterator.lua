local loop = vim.loop

local DirectoryIterator = require("MetaFly.utils.DirectoryIterator")

local NotesIterator = {}

NotesIterator.__index = NotesIterator

function NotesIterator:new(noteBoxConfig)
	local obj = setmetatable({}, self)
	local ignoredNames = { ".", "..", ".git", ".obsidian" }
	for _, v in ipairs(noteBoxConfig.ignored or {}) do
		table.insert(ignoredNames, v)
	end
	obj.root = noteBoxConfig.path:gsub("/$", "")
	obj.maxdepth = noteBoxConfig.maxdepth or 1
	obj.ignored = {}
	for _, v in ipairs(ignoredNames) do
		obj.ignored[v] = true
	end
	local rootIterator, error = DirectoryIterator.dir_iter(obj.root)
	-- print(vim.inspect(error))
	obj.ignoredEntries = {}
	obj.stack = {
		{
			dir = obj.root,
			depth = 0,
			iterator = rootIterator,
		},
	}
	return obj
end

local function is_markdown(name)
	local lower = name:lower()
	return lower:match("%.md$") or lower:match("%.markdown$")
end

local function make_info(path, attr)
	return {
		path = path,
		name = path:match("[^/\\]+$"),
		size = attr.size,
		type = attr.mode,
		modified = attr.modification,
	}
end

-- ------------------------------------------------------------
-- next(): die wichtigste Methode
-- ------------------------------------------------------------
function NotesIterator:next()
	while #self.stack > 0 do
		local top = self.stack[#self.stack]
		local entryName, entryPath, entryAttr = top.iterator()

		if entryName == nil then
			table.remove(self.stack)
		elseif not self.ignored[entryName] then
			local full = top.dir .. "/" .. entryName

			if entryAttr then
				if entryAttr.mode == "directory" then
					-- neue Ebene pushen
					local newIter, newError = DirectoryIterator.dir_iter(full)
					if top.depth < self.maxdepth then
						table.insert(self.stack, {
							dir = full,
							depth = top.depth + 1,
							iterator = newIter,
						})
					end
				elseif entryAttr.mode == "file" and is_markdown(entryName) then
					return make_info(full, entryAttr)
				end
			end
		else
			-- ignored entry
			table.insert(self.ignoredEntries, entryName)
		end
	end

	return nil
end

return NotesIterator
