local SnacksValuesPicker = require("MetaFly.picker.SnacksValuesPicker")

describe("MetaFly.picker.SnacksValuesPicker", function()
	local originalSnacks
	local originalNotify
	local options
	local notifications
	local buffer

	before_each(function()
		originalSnacks = Snacks
		originalNotify = vim.notify
		options = nil
		notifications = {}
		Snacks = { picker = { pick = function(opts) options = opts end } }
		vim.notify = function(message, level)
			table.insert(notifications, { message, level })
		end
		buffer = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(buffer)
		vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "before AFTER" })
		vim.api.nvim_win_set_cursor(0, { 1, 7 })
	end)

	after_each(function()
		Snacks = originalSnacks
		vim.notify = originalNotify
		if vim.api.nvim_buf_is_valid(buffer) then
			vim.api.nvim_buf_delete(buffer, { force = true })
		end
	end)

	local function picker(selected)
		return {
			closed = false,
			selected = function() return selected end,
			close = function(self) self.closed = true end,
		}
	end

	it("inserts the current value at the original cursor when nothing is marked", function()
		SnacksValuesPicker.open({ "apple", "pear" })
		local instance = picker({})
		options.confirm(instance, options.items[2])

		assert.is_true(instance.closed)
		assert.are.same({ "before pearAFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)

	it("inserts marked values in selection order separated by commas", function()
		SnacksValuesPicker.open({ "apple", "pear", "plum" })
		local instance = picker({ options.items[3], options.items[1] })
		options.confirm(instance, options.items[2])

		assert.are.same({ "before plum, appleAFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)

	it("inserts marked values as Markdown items, preserving surrounding text", function()
		SnacksValuesPicker.open({ "äpfel", "pear" })
		local instance = picker({ options.items[1], options.items[2] })
		options.actions.insert_markdown(instance, nil)

		assert.are.same({ "before - äpfel", "- pearAFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)

	it("keeps duplicate values independently selectable", function()
		SnacksValuesPicker.open({ "same", "same" })
		assert.are_not.equal(options.items[1]._select_key, options.items[2]._select_key)
		local instance = picker({ options.items[1], options.items[2] })
		options.confirm(instance, nil)
		assert.are.same({ "before same, sameAFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)

	it("inserts into the original buffer even if another buffer becomes current", function()
		SnacksValuesPicker.open({ "apple" })
		local other = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_current_buf(other)
		options.confirm(picker({}), options.items[1])
		assert.are.same({ "before appleAFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
		vim.api.nvim_buf_delete(other, { force = true })
	end)

	it("does not close or insert when no item is selected", function()
		SnacksValuesPicker.open({ "apple" })
		local instance = picker({})
		options.confirm(instance, nil)
		assert.is_false(instance.closed)
		assert.are.equal(vim.log.levels.WARN, notifications[1][2])
		assert.are.same({ "before AFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)

	it("reports invalid and empty input without opening the picker", function()
		SnacksValuesPicker.open({ "valid", "two\nlines" })
		assert.is_nil(options)
		assert.are.equal(vim.log.levels.ERROR, notifications[1][2])
		SnacksValuesPicker.open({})
		assert.is_nil(options)
		assert.are.equal(vim.log.levels.WARN, notifications[2][2])
	end)

	it("reports insertion errors for a nonmodifiable buffer", function()
		SnacksValuesPicker.open({ "apple" })
		vim.bo[buffer].modifiable = false
		options.confirm(picker({}), options.items[1])
		assert.are.equal(vim.log.levels.ERROR, notifications[1][2])
		assert.are.same({ "before AFTER" }, vim.api.nvim_buf_get_lines(buffer, 0, -1, false))
	end)
end)
