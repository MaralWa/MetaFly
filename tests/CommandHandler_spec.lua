local CommandHandler = require("MetaFly.command.CommandHandler")

describe("MetaFly.command.CommandHandler", function()
	it("should have execute function", function()
		assert.is_not_nil(CommandHandler.execute)
		assert.is_function(CommandHandler.execute)
	end)

	it("should have executePicker function", function()
		assert.is_not_nil(CommandHandler.executePicker)
		assert.is_function(CommandHandler.executePicker)
	end)

	it("should have executeNotes function", function()
		assert.is_not_nil(CommandHandler.executeNotes)
		assert.is_function(CommandHandler.executeNotes)
	end)

	it("should have executeUri function", function()
		assert.is_not_nil(CommandHandler.executeUri)
		assert.is_function(CommandHandler.executeUri)
	end)

	it("should have executeSqlResult function", function()
		assert.is_not_nil(CommandHandler.executeSqlResult)
		assert.is_function(CommandHandler.executeSqlResult)
	end)
end)
