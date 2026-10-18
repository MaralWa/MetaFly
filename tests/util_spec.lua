local util = require("MetaFly.utils.Utils")

describe("MetaFly.utils.Utils", function()
	it("entfernt einen abschließenden Punkt", function()
		assert.are.equal("file.txt", util.remove_suffix("file.txt.", "."))
	end)

	it("macht nichts, wenn das Suffix nicht vorhanden ist", function()
		assert.are.equal("test", util.remove_suffix("test", "."))
	end)

	it("entfernt ein mehrbyte Unicode-Suffix (Emoji)", function()
		assert.are.equal("Grüße", util.remove_suffix("Grüße😊", "😊"))
	end)

	it("gibt unverändert zurück, wenn suffix länger als string", function()
		assert.are.equal("a", util.remove_suffix("a", "longsuffix"))
	end)

	it("Checks if placeholders are correctly extracted from a string", function()
		local input = "Hello, {{name}}! Welcome to {{place}}."
		local expected = { "name", "place" }
		assert.are.same(expected, util.extractPlaceholders(input))
	end)
end)
