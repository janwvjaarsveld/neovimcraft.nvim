return require("telescope").register_extension({
	exports = {
		plugins = require("neovimcraft").search_plugins,
		tags = require("neovimcraft").search_tags,
	},
})
