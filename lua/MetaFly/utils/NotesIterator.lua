local lfs = require("lfs")

local NotesIterator = {}

NotesIterator.__index = NotesIterator

function NotesIterator:new(root, maxdepth)
	local obj = setmetatable({}, self)
	obj.root = root
	obj.maxdepth = maxdepth or math.huge
	local rootIterator, rootState, rootEntry = lfs.dir(root)
	obj.stack = { {
		dir = root,
		depth = 0,
		iterator = rootIterator,
		state = rootState,
		entry = rootEntry,
	} }
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
		local entry = top.iterator(top.state, top.entry)

		if entry == nil then
			table.remove(self.stack)
		elseif entry ~= "." and entry ~= ".." and entry ~= ".git" then
			local full = top.dir .. "/" .. entry

			local attr = lfs.attributes(full)
			if attr then
				if attr.mode == "directory" then
					-- neue Ebene pushen
					local newIter, newState, newEntry = lfs.dir(full)
					if top.depth < self.maxdepth then
						table.insert(self.stack, {
							dir = full,
							depth = top.depth + 1,
							iterator = newIter,
							state = newState,
							entry = newEntry,
						})
					end
				elseif attr.mode == "file" and is_markdown(entry) then
					return make_info(full, attr)
				end
			end
		end
	end

	return nil -- fertig
end

-- ------------------------------------------------------------
-- PUBLIC API
-- ------------------------------------------------------------
local function markdown_files(root, maxdepth)
	return NotesIterator:new(root, maxdepth)
end

notes = markdown_files("/Users/sarah/Documents/vimwiki", 2)
