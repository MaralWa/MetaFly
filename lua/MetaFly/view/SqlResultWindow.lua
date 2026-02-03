local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local SqlResultWindow = {}

---@class SqlResultWindow
---@field popup NuiPopup
---@field content table
local SqlResultWindow = {
	popup = nil,
	content = {},
}

---Creates a new SqlResultWindow instance
---@param title string|nil Optional title for the window
---@return SqlResultWindow
function SqlResultWindow:new(title)
	local newObject = setmetatable({}, self)
	self.__index = self

	newObject.content = {}
	newObject.popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
			text = {
				top = title or " SQL Result ",
				top_align = "center",
			},
		},
		position = "50%",
		size = {
			width = "80%",
			height = "70%",
		},
		buf_options = {
			modifiable = false,
			readonly = true,
		},
	})

	-- Set up keymaps for the popup
	newObject:setupKeymaps()

	-- Unmount component when cursor leaves buffer
	newObject.popup:on(event.BufLeave, function()
		newObject.popup:unmount()
	end)

	return newObject
end

---Sets up keyboard mappings for the window
function SqlResultWindow:setupKeymaps()
	local bufnr = self.popup.bufnr

	-- Copy content to clipboard (y)
	vim.keymap.set("n", "y", function()
		self:copyToClipboard()
	end, { buffer = bufnr, desc = "Copy content to clipboard" })

	-- Save to current buffer (s)
	vim.keymap.set("n", "s", function()
		self:saveToCurrentBuffer()
	end, { buffer = bufnr, desc = "Save to current buffer" })

	-- Save to new file (w)
	vim.keymap.set("n", "w", function()
		self:saveToNewFile()
	end, { buffer = bufnr, desc = "Save to new file" })

	-- Close window (q)
	vim.keymap.set("n", "q", function()
		self.popup:unmount()
	end, { buffer = bufnr, desc = "Close window" })
end

---Opens the window
function SqlResultWindow:open()
	self.popup:mount()
end

---Sets the content of the window
---@param lines table Array of strings to display
function SqlResultWindow:setContent(lines)
	self.content = lines
	vim.api.nvim_buf_set_option(self.popup.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(self.popup.bufnr, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(self.popup.bufnr, "modifiable", false)
end

---Copies the window content to clipboard
function SqlResultWindow:copyToClipboard()
	local content = table.concat(self.content, "\n")
	vim.fn.setreg("+", content)
	vim.notify("Content copied to clipboard!", vim.log.levels.INFO)
end

---Saves content to the current buffer (the one that was active before opening the popup)
function SqlResultWindow:saveToCurrentBuffer()
	-- Get the previous window (the one before the popup)
	local prev_win = vim.fn.win_getid(vim.fn.winnr("#"))
	
	if prev_win == 0 or not vim.api.nvim_win_is_valid(prev_win) then
		vim.notify("No valid previous window found", vim.log.levels.WARN)
		return
	end

	local prev_buf = vim.api.nvim_win_get_buf(prev_win)
	
	-- Close the popup first
	self.popup:unmount()
	
	-- Switch to the previous window
	vim.api.nvim_set_current_win(prev_win)
	
	-- Insert content at cursor position
	local cursor_pos = vim.api.nvim_win_get_cursor(prev_win)
	local line = cursor_pos[1] - 1
	
	vim.api.nvim_buf_set_lines(prev_buf, line, line, false, self.content)
	vim.notify("Content inserted into buffer!", vim.log.levels.INFO)
end

---Saves content to a new file
function SqlResultWindow:saveToNewFile()
	-- Close the popup
	self.popup:unmount()
	
	-- Prompt for filename
	vim.ui.input({ prompt = "Enter filename: " }, function(filename)
		if filename and filename ~= "" then
			-- Create new buffer
			vim.cmd("new " .. vim.fn.fnameescape(filename))
			local bufnr = vim.api.nvim_get_current_buf()
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, self.content)
			vim.notify("Content saved to " .. filename, vim.log.levels.INFO)
		else
			vim.notify("Save cancelled", vim.log.levels.WARN)
		end
	end)
end

---Display SQL result from database:callSql
---@param database table The database instance
---@param statement string The SQL statement to execute
---@param mode string|nil Optional mode parameter for callSql
---@param title string|nil Optional window title
function SqlResultWindow.displaySqlResult(database, statement, mode, title)
	local sqlResult = database:callSql(statement, mode)
	local lines = {}
	
	if sqlResult ~= nil then
		for line in sqlResult:lines() do
			table.insert(lines, line)
		end
		sqlResult:close()
	else
		lines = { "No results returned" }
	end
	
	-- Create window with title
	local window = SqlResultWindow:new(title or " SQL Result ")
	window:setContent(lines)
	window:open()
	
	-- Add help text at the bottom
	local help_text = {
		"",
		"─────────────────────────────────",
		"Keyboard commands:",
		"  y - Copy to clipboard",
		"  s - Save to current buffer",
		"  w - Save to new file",
		"  q - Close window",
	}
	
	-- Append help text
	vim.api.nvim_buf_set_option(window.popup.bufnr, "modifiable", true)
	vim.api.nvim_buf_set_lines(window.popup.bufnr, -1, -1, false, help_text)
	vim.api.nvim_buf_set_option(window.popup.bufnr, "modifiable", false)
end

return SqlResultWindow
