return require("telescope").register_extension({
	exports = {
		search_plugins = require("neovimcraft").search_plugins,
		search_tags = require("neovimcraft").search_tags,
	},
})
