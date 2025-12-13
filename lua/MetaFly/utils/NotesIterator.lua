local lfs = require("lfs")

local NotesIterator = {}

NotesIterator.__index = NotesIterator

function NotesIterator:new(root, maxdepth)
	local obj = setmetatable({}, self)
	obj.root = root
	obj.maxdepth = maxdepth or math.huge
	obj.stack = { { dir = root, depth = 0, iter = lfs.dir(root) } }
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
		local entry = top.iter()

		if entry == nil then
			table.remove(self.stack)
		else
			if entry ~= "." and entry ~= ".." then
				local full = top.dir .. "/" .. entry

				-- .git Ordner explizit überspringen
				if entry == ".git" then
					-- continue
				else
					local attr = lfs.attributes(full)
					if attr then
						if attr.mode == "directory" then
							-- neue Ebene pushen
							if top.depth < self.maxdepth then
								table.insert(self.stack, {
									dir = full,
									depth = top.depth + 1,
									iter = lfs.dir(full),
								})
							end
						elseif attr.mode == "file" and is_markdown(entry) then
							return make_info(full, attr)
						end
					end
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

return NotesIterator
