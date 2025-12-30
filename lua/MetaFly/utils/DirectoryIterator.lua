-- lua/myplugin/fs_iter.lua
-- Dir-Iterator mit attributes-Objekt, basierend auf vim.loop (luv)
local uv = vim.loop

local M = {}

local function join_path(dir, name)
	if dir:match("[/\\]$") then
		return dir .. name
	end
	return dir .. "/" .. name
end

local function mtime_to_number(mtime)
	if not mtime then
		return nil
	end
	if type(mtime) == "table" then
		local sec = mtime.sec or mtime[1] or 0
		return sec
	end
	return tonumber(mtime)
end

-- attributes(path) -> table or nil, err
-- Returns at least: mode ("file"/"directory"/"link"/...), size (number), modification (epoch float)
function M.attributes(path)
	local st = uv.fs_stat(path)
	if not st then
		return nil, "not found or stat failed"
	end
	return {
		mode = st.type,
		size = st.size,
		modification = mtime_to_number(st.mtime),
		-- optionally you can add more fields if desired (uid/gid/etc)
	}
end

-- dir_iter(path) -> iterator function or nil, err
-- Iterator yields: name, fullpath, attributes_table
function M.dir_iter(path)
	local it, err = uv.fs_scandir(path)
	if not it then
		return nil, err
	end

	return function()
		while true do
			local name = uv.fs_scandir_next(it)
			if not name then
				return nil
			end
			if name == "." or name == ".." then
			-- skip special entries
			else
				local full = join_path(path, name)
				local st = uv.fs_stat(full)
				local attr = nil
				if st then
					attr = {
						mode = st.type,
						size = st.size,
						modification = mtime_to_number(st.mtime),
					}
				end
				return name, full, attr
			end
		end
	end
end

return M
