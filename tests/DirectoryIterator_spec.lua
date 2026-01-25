-- tests/fs_iter_spec.lua
-- Tests for myplugin.fs_iter using plenary/busted (run with :PlenaryBustedFile tests/fs_iter_spec.lua)

local uv = vim.loop

local iterator = require("MetaFly.utils.DirectoryIterator")

local function safe_rmpath(path)
	-- try unlink (file) then rmdir (dir); ignore errors
	pcall(function()
		uv.fs_unlink(path)
	end)
	pcall(function()
		uv.fs_rmdir(path)
	end)
end

describe("MetaFly.utils.DirectoryIterator", function()
	local tmpdir

	before_each(function()
		-- create a unique temporary directory for tests
		tmpdir = os.tmpname()
		-- os.tmpname may return an existing file on some systems; remove it then create dir
		pcall(function()
			os.remove(tmpdir)
		end)
		local ok, err = uv.fs_mkdir(tmpdir, tonumber("0700", 8))
		assert.is_truthy(ok, "failed to create tmpdir: " .. tostring(err))
	end)

	after_each(function()
		-- cleanup: remove files and dir
		-- remove created file and subdir if exist
		safe_rmpath(tmpdir .. "/foo.txt")
		safe_rmpath(tmpdir .. "/subdir")
		pcall(function()
			uv.fs_rmdir(tmpdir)
		end)
	end)

	it("returns attributes for a file and a directory", function()
		-- create file foo.txt with known content
		local fpath = tmpdir .. "/foo.txt"
		local fd = assert(uv.fs_open(fpath, "w", tonumber("0644", 8)))
		local s = "hello"
		assert(uv.fs_write(fd, s, -1))
		uv.fs_close(fd)

		-- create subdir
		local sub = tmpdir .. "/subdir"
		assert(uv.fs_mkdir(sub, tonumber("0755", 8)))

		-- collect entries from iterator
		local iter, err = iterator.dir_iter(tmpdir)
		assert.is_truthy(iter, "dir_iter failed: " .. tostring(err))

		local found = {}
		for name, full, attr in iter do
			assert.is_string(name)
			assert.is_string(full)
			-- store by name
			found[name] = { full = full, attr = attr }
		end

		-- check file entry
		assert.is_truthy(found["foo.txt"], "foo.txt not found in dir_iter")
		assert.are.equal(found["foo.txt"].full, fpath)
		local a = found["foo.txt"].attr
		assert.is_table(a)
		assert.are.equal("file", a.mode)
		assert.are.equal(#s, a.size)
		assert.is_number(a.modification)

		-- check directory entry
		assert.is_truthy(found["subdir"], "subdir not found in dir_iter")
		assert.are.equal(found["subdir"].full, sub)
		local ad = found["subdir"].attr
		assert.is_table(ad)
		assert.are.equal("directory", ad.mode)
		assert.is_number(ad.modification)
	end)

	it("attributes() returns correct info", function()
		local fpath = tmpdir .. "/bar.txt"
		local fd = assert(uv.fs_open(fpath, "w", tonumber("0644", 8)))
		local txt = "abcde"
		assert(uv.fs_write(fd, txt, -1))
		uv.fs_close(fd)

		local attr, err = iterator.attributes(fpath)
		assert.is_table(attr, "attributes failed: " .. tostring(err))
		assert.are.equal("file", attr.mode)
		assert.are.equal(#txt, attr.size)
		assert.is_number(attr.modification)
	end)

	it("iterate over TestData directory", function()
		local testdata_dir = "tests/TestData"
		local iter, err = iterator.dir_iter(testdata_dir)
		local iterNext, erNextr = iterator.dir_iter(testdata_dir)
		assert.is_truthy(iter, "dir_iter failed: " .. tostring(err))

		local nextName, nextFull, nextAttr = iterNext()
		print("Next entry from iterNext:", nextName, nextFull, nextAttr and nextAttr.modification or "nil")
		for key, value in pairs(nextAttr or {}) do
			print("  " .. key .. ": " .. tostring(value))
		end

		local entries = {}
		for name, full, attr in iter do
			table.insert(entries, { name = name, full = full, attr = attr })
		end

		print(#entries > 0, "No entries found in TestData directory " .. #entries)
		-- Check that we found some expected files/directories
		-- Expected entries:
		local expectedEntries = { "240302011450.md", "251029202020.md", "251130171717.md" }
		local foundEntries = 0
		for _, entry in ipairs(entries) do
			print(entry.name)
			for _, expected in ipairs(expectedEntries) do
				if entry.name == expected then
					foundEntries = foundEntries + 1
				end
			end
		end
		assert.are.equal(#expectedEntries, foundEntries, "Not all expected entries found in TestData")
	end)
end)
