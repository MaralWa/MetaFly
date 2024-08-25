local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

MetaFlyPopUp = {}

---@class MetaFlyPopUp
---@field popup
local MetaFlyPopUp = {
	popup,
}

function MetaFlyPopUp:new()
	local newObject = setmetatable({}, self)
	self.__index = self

	self.popup = Popup({
		enter = true,
		focusable = true,
		border = {
			style = "rounded",
		},
		position = "50%",
		size = {
			width = "80%",
			height = "60%",
		},
	})
	-- unmount component when cursor leaves buffer
	self.popup:on(event.BufLeave, function()
		self.popup:unmount()
	end)
	return newObject
end

function MetaFlyPopUp:open()
	self.popup:mount()
end

---@param lines table
function MetaFlyPopUp:appendLines(lines)
	vim.api.nvim_buf_set_lines(self.popup.bufnr, -1, -1, false, lines)
end

---@param line string
function MetaFlyPopUp:appendLine(line)
	self:appendLines({ line })
end

return MetaFlyPopUp
