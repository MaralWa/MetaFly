local YamlHeader = require("MetaFly.model.YamlHeader")

describe("MetaFly.model.YamlHeader", function()
	local tmpdir

	it("creates a new YamlHeader object", function()
		local yh = YamlHeader:new("testfile.md", 1)
		assert.is_table(yh)
		assert.equals("testfile.md", yh.fileName)
		assert.equals(1, yh.bufferNumber)
		assert.is_table(yh.header)
		assert.is_table(yh.headerLines)
		assert.is_table(yh.warnings)
		assert.is_table(yh.mappings)
		assert.is_table(yh.noteData)
		assert.is_table(yh.metaData)
	end)
end)
