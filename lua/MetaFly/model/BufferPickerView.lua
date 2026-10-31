local MetaFlyView = require("MetaFly.model.MetaFlyView")
local PickerView = require("MetaFly.model.PickerView")
local Utils = require("MetaFly.utils.Utils")
local logger = require("MetaFly.config"):getInstance():getLogger().child("view").child("BufferPickerView")

local BufferPickerView = setmetatable({}, { __index = MetaFlyView }) -- erbt von MetaFlyView
BufferPickerView.__index = BufferPickerView

local selectStatement = [[
WITH input(datei) AS (
  VALUES {{BUFFER_PATHS}}),
notes AS (
  SELECT Note.id,
         Note.title,
         NoteBox.path || '/' || Note.fileName AS datei
  FROM Note
  JOIN NoteBox ON Note.idNoteBox = NoteBox.id
)
SELECT
  COALESCE(
    notes.title,
    input.datei
  ) AS text,
  input.datei as file
FROM input
LEFT JOIN notes ON notes.datei = input.datei
order by text desc;
]]

setmetatable(BufferPickerView, {
	__index = MetaFly, -- Inherit from MetaFlyView to overload the getSelectStatement method
})

function BufferPickerView.new()
	local self = MetaFlyView.new({
		name = "Buffer Picker",
		type = "Picker",
		description = "Picks buffers by the note title or the buffer path",
		columns = PickerView.columns,
	})
	setmetatable(self, BufferPickerView)
	return self
end

---@return string|nil
function BufferPickerView:getSelectStatement()
	local bufferNames = Utils.getBufferNames()
	local bufferPaths = ""
	for i, name in ipairs(bufferNames) do
		bufferPaths = bufferPaths .. "('" .. name .. "')"
		if i < #bufferNames then
			bufferPaths = bufferPaths .. ", "
		end
	end

	local statement = selectStatement:gsub("{{BUFFER_PATHS}}", bufferPaths)
	logger:debug("Generated SQL statement: %s", statement)
	return statement
end

return BufferPickerView
