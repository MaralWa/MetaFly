local BufferValidator = require("MetaFly.view.BufferValidator")

describe("MetaFly.view.BufferValidator", function()
	describe("validate", function()
		it("returns false and empty array for nil input", function()
			local hasErrors, results = BufferValidator.validate(nil)
			assert.is_false(hasErrors)
			assert.are.same({}, results)
		end)

		it("returns false and empty array for empty buffer", function()
			local hasErrors, results = BufferValidator.validate({})
			assert.is_false(hasErrors)
			assert.are.same({}, results)
		end)

		it("returns false and empty array for buffer without MetaFly markers", function()
			local lines = {
				"# Some Markdown",
				"",
				"This is a normal document without any MetaFly markers.",
				"",
				"End of document.",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_false(hasErrors)
			assert.are.same({}, results)
		end)

		it("returns false and region info for a single valid region", function()
			local lines = {
				"Some text before",
				'<!-- MetaFlyViewBegin "notes" -->',
				"| Title | Path |",
				"| Note1 | /path1 |",
				'<!-- MetaFlyViewEnd "notes" -->',
				"Some text after",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_false(hasErrors)
			assert.are.same({ { beginLine = 2, endLine = 5 } }, results)
		end)

		it("returns false and region info for multiple non-overlapping regions", function()
			local lines = {
				'<!-- MetaFlyViewBegin "view1" -->',
				"content 1",
				'<!-- MetaFlyViewEnd "view1" -->',
				"",
				'<!-- MetaFlyViewBegin "view2" -->',
				"content 2",
				'<!-- MetaFlyViewEnd "view2" -->',
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_false(hasErrors)
			assert.are.same({
				{ beginLine = 1, endLine = 3 },
				{ beginLine = 5, endLine = 7 },
			}, results)
		end)

		it("detects missing end marker", function()
			local lines = {
				'<!-- MetaFlyViewBegin "notes" -->',
				"| Title | Path |",
				"| Note1 | /path1 |",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			assert.are.equal(1, #results)
			assert.are.equal(1, results[1].line)
			assert.is_truthy(results[1].message:find("Fehlende Endmarkierung"))
		end)

		it("detects missing begin marker", function()
			local lines = {
				"| Title | Path |",
				"| Note1 | /path1 |",
				'<!-- MetaFlyViewEnd "notes" -->',
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			assert.are.equal(1, #results)
			assert.are.equal(3, results[1].line)
			assert.is_truthy(results[1].message:find("Fehlende Anfangsmarkierung"))
		end)

		it("detects overlapping regions", function()
			local lines = {
				'<!-- MetaFlyViewBegin "view1" -->',
				"content 1",
				'<!-- MetaFlyViewBegin "view2" -->',
				"content 2",
				'<!-- MetaFlyViewEnd "view1" -->',
				'<!-- MetaFlyViewEnd "view2" -->',
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			assert.is_truthy(#results > 0)
			-- The second begin marker triggers the overlap error
			assert.are.equal(3, results[1].line)
			assert.is_truthy(results[1].message:find("Überlappender Bereich"))
		end)

		it("detects mismatched begin and end names", function()
			local lines = {
				'<!-- MetaFlyViewBegin "view1" -->',
				"content",
				'<!-- MetaFlyViewEnd "view2" -->',
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			assert.are.equal(1, #results)
			assert.are.equal(3, results[1].line)
			assert.is_truthy(results[1].message:find("stimmt nicht mit Anfangsmarkierung"))
		end)

		it("handles region at first and last lines", function()
			local lines = {
				'<!-- MetaFlyViewBegin "edge" -->',
				'<!-- MetaFlyViewEnd "edge" -->',
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_false(hasErrors)
			assert.are.same({ { beginLine = 1, endLine = 2 } }, results)
		end)

		it("returns multiple errors when multiple issues exist", function()
			local lines = {
				'<!-- MetaFlyViewEnd "orphan" -->',
				"",
				'<!-- MetaFlyViewBegin "unclosed" -->',
				"content",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			assert.are.equal(2, #results)
			-- First error: end without begin
			assert.are.equal(1, results[1].line)
			assert.is_truthy(results[1].message:find("Fehlende Anfangsmarkierung"))
			-- Second error: begin without end
			assert.are.equal(3, results[2].line)
			assert.is_truthy(results[2].message:find("Fehlende Endmarkierung"))
		end)

		it("handles mixed valid and invalid regions", function()
			local lines = {
				'<!-- MetaFlyViewBegin "valid" -->',
				"content",
				'<!-- MetaFlyViewEnd "valid" -->',
				"",
				'<!-- MetaFlyViewBegin "broken" -->',
				"more content",
			}
			local hasErrors, results = BufferValidator.validate(lines)
			assert.is_true(hasErrors)
			-- Even though first region is valid, the unclosed second region is an error
			assert.is_truthy(#results > 0)
		end)
	end)
end)
