local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local curl = require("plenary.curl")

--- @class Plugin
--- @field id string The ID of the plugin
--- @field name string The name of the plugin
--- @field username string The username of the plugin owner
--- @field repo string The repository name of the plugin
--- @field link string The GitHub URL of the plugin
--- @field tags string[] The tags of the plugin
--- @field homepage string The homepage of the plugin
--- @field description string A brief description of the plugin
--- @field branch string The default branch of the plugin
--- @field openIssues string The number of open issues
--- @field watcher number The number of watchers the plugin has
--- @field forks number The number of forks the plugin has
--- @field stars number The number of stars the plugin has
--- @field subscribers number The number of subscribers the plugin has
--- @field network number The number of network the plugin has
--- @field createdAt string The date the plugin was created
--- @field updatedAt string The last updated date

--- @alias endpointTypes "search_plugins"|"search_tags"|"search_by_tag"
--- @enum EndpointTypes
local EndpointTypes = {
	search_plugins = "search_plugins",
	search_tags = "search_tags",
	search_by_tag = "search_by_tag",
}

local M = {}

---@class WindowConfig
---@field width_ratio number
---@field height_ratio number
---@field border string

---@class CommandNames
---@field search_plugins string
---@field search_tags string
---@field search_by_tag string

---@class KeyBindings
---@field close string
---@field open_git string

---@class CacheTTL
---@field search_plugins number
---@field search_tags number

---@class Config
---@field window WindowConfig
---@field setup_user_commands boolean
---@field command_names CommandNames
---@field key_bindings KeyBindings
---@field cache_ttl CacheTTL

-- Default configuration
---@type Config
local config = {
	-- Floating window configuration
	window = {
		width_ratio = 0.6, -- The fraction of the editor's width
		height_ratio = 0.8, -- The fraction of the editor's height
		border = "double", -- Available options: 'none', 'single', 'double', 'rounded', etc.
	},
	setup_user_commands = false,
	-- User command name
	command_names = {
		search_plugins = "NeovimcraftPlugins",
		search_tags = "NeovimcraftTags",
		search_by_tag = "NeovimcraftByTag",
	},
	-- Keymap: pass map = false to skip setting a keymap
	key_bindings = {
		close = "q", -- Optional: Change close key to 'x'
		open_git = "o",
	},
	cache_ttl = {
		search_plugins = 24 * 3600, -- 24 hours
		search_tags = 24 * 3600, -- 24 hours
	},
}

-- Cache for plugins and tags
local cache = {
	search_plugins = {
		---@type Plugin[]
		content = nil,
		last_update = 0,
		ttl = config.cache_ttl.search_plugins,
	},
	search_tags = {
		---@type string[]
		content = nil,
		last_update = 0,
		ttl = config.cache_ttl.search_tags,
	},
}

-- Calculate width and height based on the editor's dimensions
local function get_window_size()
	local width = math.floor(vim.o.columns * config.window.width_ratio)
	local height = math.floor(vim.o.lines * config.window.height_ratio)
	return width, height
end

-- Fetch data from nvim.sh API
---@param type endpointTypes The type of cache to update
---@param  search_term? string The search term to use
---@return Plugin[]|string[]|nil The fetched data
local function fetch_data(type, search_term)
	---@type table<endpointTypes, string>
	local endpoints = {
		search_plugins = "s",
		search_tags = "t",
		search_by_tag = "t/",
	}
	local endpoint = endpoints[type]
	if not endpoint then
		return nil
	end

	local url = "https://nvim.sh/" .. endpoint
	if type == EndpointTypes.search_by_tag then
		if not search_term then
			return nil
		end
		url = url .. search_term
	end

	local response = curl.get(url .. "?format=json", { headers = { Accept = "application/json" } })
	if response.status == 200 then
		local body = vim.fn.json_decode(response.body)

		if type == EndpointTypes.search_plugins or type == EndpointTypes.search_by_tag then
			local plugins = {}
			for _, result in ipairs(body.results) do
				if result.plugin then
					table.insert(plugins, result.plugin)
				end
			end
			return plugins
		else
			return body.tags
		end
	end
	return nil
end

local function get_url(plugin)
	return string.format(
		"https://raw.githubusercontent.com/%s/%s/%s/%s",
		plugin.username,
		plugin.repo,
		plugin.branch,
		"README.md"
	)
end

---@param plugin Plugin
local function retrieve_plugin_readme(plugin)
	local url = get_url(plugin)
	local result = curl.get(url)
	if result.status ~= 200 then
		return nil
	end

	return vim.split(result.body, "\n")
end

-- Update cache if needed
--- @param type endpointTypes The type of cache to update
local function update_cache(type)
	local current_time = os.time()
	if not cache[type].content or (current_time - cache[type].last_update) > cache[type].ttl then
		local response = fetch_data(type)
		if not response then
			return
		end
		cache[type].content = response
		cache[type].last_update = current_time
	end
end

--- Create a floating window with config-based width and height.
--- @param opts table: { buf = <buf_handle>, title = <string> }
local function create_floating_window(opts)
	opts = opts or { title = "Neovim Plugin info" }
	local width, height = get_window_size()
	-- Calculate position for centering
	local col = math.floor((vim.o.columns - width) / 2)
	local row = math.floor((vim.o.lines - height) / 2)

	-- Create or reuse the given buffer
	local buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer

	local win_config = {
		relative = "editor",
		width = width,
		height = height,
		col = col,
		row = row,
		style = "minimal",
		border = config.window.border,
		title = opts.title,
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)
	return { buf = buf, win = win }
end

-- Format plugin entry for display
---@param plugin Plugin
local function format_plugin(plugin)
	local name = plugin.name or "Unknown"
	return string.format("%s", name)
end

---@param plugin Plugin
local function format_plugin_preview(plugin)
	local name = plugin.name or "Unknown"
	local description = plugin.description or "No description available"
	local stars = plugin.stars or 0
	local forks = plugin.forks or 0
	local openIssues = plugin.openIssues or 0
	local createdAt = plugin.createdAt or "Unknown"
	local updatedAt = plugin.updatedAt or "Unknown"
	local author = plugin.username or "Unknown Author" -- Assuming the author's name is stored in the username field
	local tags = plugin.tags or {}
	local link = plugin.link or "Unknown"

	-- Return a table with each line of formatted output
	local content = {
		string.format("### %s", name),
		"",
		string.format("**Author:** %s", author),
		string.format("**Description:** %s", description),
		"",
		string.format("**Stars:** %d", stars),
		string.format("**Forks:** %d", forks),
		string.format("**Open Issues:** %d", openIssues),
		string.format("**Created At:** %s", createdAt),
		string.format("**Updated At:** %s", updatedAt),
		"",
		"**Tags:**",
	}
	-- Create a bullet point list for tags
	for _, tag in ipairs(tags) do
		table.insert(content, string.format(" - `%s`", tag))
	end
	table.insert(content, "")
	table.insert(content, string.format("**GitHub Link:** [View on GitHub](%s)", link))

	return content
end

-- Create plugin previewer
local plugin_previewer = previewers.new_buffer_previewer({
	title = "Plugin Details",
	define_preview = function(self, entry)
		local plugin = entry.value
		local content = format_plugin_preview(plugin)
		vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, content)
		vim.api.nvim_set_option_value("filetype", "markdown", { buf = self.state.bufnr })
	end,
})

local function plugin_picker(opts, content)
	if not content then
		vim.notify("No content to diplay", vim.log.levels.ERROR)
		return
	end

	pickers
		.new(opts, {
			prompt_title = opts.tag and ("Neovim Plugins [" .. opts.tag .. "]") or "Neovim Plugins",
			finder = finders.new_table({
				results = content,
				---@param plugin Plugin
				entry_maker = function(plugin)
					return {
						value = plugin,
						display = format_plugin(plugin),
						ordinal = plugin.name,
					}
				end,
			}),
			sorter = sorters.get_fzy_sorter(opts),
			previewer = plugin_previewer,
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					local plugin = selection.value

					-- Create/reuse floating window
					local floating = create_floating_window({
						title = plugin.name,
					})
					vim.api.nvim_buf_set_name(floating.buf, plugin.name .. "README.md")

					if vim.fn.executable("glow") == 1 then
						vim.api.nvim_set_option_value("filetype", "terminal", { buf = floating.buf })
						-- vim.api.nvim_win_set_option("winblend", 0, { win = floating.win })
						vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = floating.buf })
						vim.api.nvim_set_option_value("filetype", "glowpreview", { buf = floating.buf })
						vim.fn.termopen({ "glow", get_url(plugin) })
					else
						-- Clear existing content and insert the fetched lines
						local lines = retrieve_plugin_readme(plugin)
						if not lines then
							lines = { "Failed to fetch README.md" }
						end
						vim.api.nvim_buf_set_lines(floating.buf, 0, -1, false, lines)

						-- Buffer/window settings
						vim.api.nvim_set_option_value("wrap", true, { win = floating.win })
						vim.api.nvim_set_option_value("modifiable", false, { buf = floating.buf })
						vim.api.nvim_set_option_value("bufhidden", "delete", { buf = floating.buf })
						vim.api.nvim_set_option_value("buftype", "nofile", { buf = floating.buf })
						vim.api.nvim_set_option_value("filetype", "markdown", { buf = floating.buf })
					end
					-- Keymaps in floating buffer
					vim.api.nvim_buf_set_keymap(
						floating.buf,
						"n",
						config.key_bindings.close,
						string.format([[<cmd>lua vim.api.nvim_win_close(%d, true)<CR>]], floating.win),
						{ noremap = true, silent = true }
					)
					vim.api.nvim_buf_set_keymap(
						floating.buf,
						"n",
						"<esc>",
						string.format([[<cmd>lua vim.api.nvim_win_close(%d, true)<CR>]], floating.win),
						{ noremap = true, silent = true }
					)
					vim.api.nvim_buf_set_keymap(
						floating.buf,
						"n",
						config.key_bindings.open_git,
						string.format([[<cmd>lua vim.ui.open("%s")<CR>]], plugin.link),
						{ noremap = true, silent = true }
					)
				end)
				return true
			end,
		})
		:find()
end

-- Main plugin search function
function M.search_by_tag(opts)
	opts = opts or {}

	local content = fetch_data(EndpointTypes.search_by_tag, opts.search_term)
	plugin_picker(opts, content)
end

-- Main plugin search function
function M.search_plugins(opts)
	opts = opts or {}
	update_cache(EndpointTypes.search_plugins)

	local content = cache.search_plugins.content
	if not content then
		vim.notify("Failed to fetch data from nvim.sh", vim.log.levels.ERROR)
		return
	end
	plugin_picker(opts, content)
end

-- List available tags
function M.search_tags(opts)
	opts = opts or {}
	update_cache(EndpointTypes.search_tags)

	local content = cache.search_tags.content

	if not content then
		vim.notify("Failed to fetch data from nvim.sh", vim.log.levels.ERROR)
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Neovim Plugin Tags",
			finder = finders.new_table({
				results = content,
				entry_maker = function(tag)
					return {
						value = tag,
						display = tag,
						ordinal = tag,
					}
				end,
			}),
			sorter = sorters.get_fzy_sorter(opts),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					-- Search plugins with selected tag
					M.search_by_tag({ search_term = selection.value })
				end)
				return true
			end,
		})
		:find()
end

--- Setup function to initialize user config and commands.
--- @param user_config? table: The user configuration
function M.setup(user_config)
	config = vim.tbl_deep_extend("force", config, user_config or {})
	if config.setup_user_commands then
		M.setup_user_commands()
	end
end

function M.setup_user_commands()
	vim.api.nvim_create_user_command(config.command_names.search_plugins, function(opts)
		M.search_plugins(opts)
	end, {
		desc = string.format("Search all plugins from Neovimcraft"),
	})
	vim.api.nvim_create_user_command(config.command_names.search_tags, function(opts)
		M.search_tags(opts)
	end, {
		desc = string.format("List all tags from Neovimcraft"),
	})
	vim.api.nvim_create_user_command(config.command_names.search_by_tag, function(opts)
		local args = opts.fargs
		opts = vim.tbl_extend("force", opts, { search_term = args[1] })
		M.search_by_tag(opts)
	end, {
		desc = string.format("List all tags from Neovimcraft"),
	})
end

return M
