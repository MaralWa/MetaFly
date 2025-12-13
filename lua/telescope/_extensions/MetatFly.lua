return require("telescope").register_extension({
	-- isetup = function(ext_config, config)
	-- access extension config and user config
	-- iend,
	exports = {
		notes = require("MetaFly.picker.NotePicker").notes,
	},
})
