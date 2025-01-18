return require("telescope").register_extension({
	exports = {
		seach_plugins = require("neovimcraft").search_plugins,
		search_tags = require("neovimcraft").search_tags,
	},
})
