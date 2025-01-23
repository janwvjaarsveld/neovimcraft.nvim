local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local curl = require("plenary.curl")
local neo_util = require("neovimcraft.util")

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

local M = {}

---@class WindowConfig
---@field width_ratio number
---@field height_ratio number
---@field border string

---@class CommandNames
---@field search_plugins string
---@field search_tags string

---@class KeyBindings
---@field close string
---@field open_git string
---@field back_to_search string

---@class Config
---@field readme_window WindowConfig
---@field setup_user_commands boolean
---@field command_names CommandNames
---@field key_bindings KeyBindings
---@field cache_refesh_rate number

-- Default configuration
---@type Config
local config = {
	cache_path = vim.fn.stdpath("cache"),
	update_cache_at_start = false, -- If false, the cache will be updated on the first search
	-- Floating window configuration
	readme_window = {
		width_ratio = 0.6, -- The fraction of the editor's width
		height_ratio = 0.8, -- The fraction of the editor's height
		border = "double", -- Available options: 'none', 'single', 'double', 'rounded', etc.
	},
	setup_user_commands = true,
	-- User command name
	command_names = {
		search_plugins = "NeovimcraftPlugins",
		search_tags = "NeovimcraftTags",
	},
	-- Keymap: pass map = false to skip setting a keymap
	key_bindings = {
		close = "q", -- Optional: Change close key to 'x'
		open_git = "o",
		back_to_search = "<BS>",
	},
	cache_refesh_rate = 24 * 3600, -- 24 hours
}

local isCacheLoaded = false

-- Cache for plugins and tags
local cache = {
	last_update = 0,
	---@type Plugin[]
	plugins = {},
	---@type string[]
	tags = {},
}

-- Calculate width and height based on the editor's dimensions
local function get_window_size()
	local width = math.floor(vim.o.columns * config.readme_window.width_ratio)
	local height = math.floor(vim.o.lines * config.readme_window.height_ratio)
	return width, height
end

-- Fetch data from the API db.json endpoint
local function refresh_data()
	local current_time = os.time()
	local data = neo_util.load_db(config.cache_path)
	if data then
		local last_update = data.last_update
		if (current_time - last_update) < config.cache_refesh_rate then
			cache.last_update = last_update
			for _, plugin in pairs(data.plugins) do
				if plugin then
					table.insert(cache.plugins, plugin)
				end
			end
			cache.tags = data.tags
			isCacheLoaded = true
			return
		end
	else
		-- If the cache is older than the TTL, fetch the data from the API
		local response = curl.get("https://neovimcraft.com/db.json", { headers = { Accept = "application/json" } })
		if response.status == 200 then
			local body = vim.json.decode(response.body)
			local response_plugins = body.plugins

			local tags = {}
			for _, plugin in pairs(response_plugins) do
				if plugin then
					table.insert(cache.plugins, plugin)
					for _, tag in ipairs(plugin.tags) do
						tags[tag] = true
					end
				end
			end

			cache.last_update = current_time
			for tag, _ in pairs(tags) do
				table.insert(cache.tags, tag)
			end
			isCacheLoaded = true

			-- Save the data to a file
			local cached_data = {
				tags = cache.tags,
				plugins = response_plugins,
				last_update = current_time,
			}

			-- Write the data to a file
			neo_util.save_db(cached_data, config.cache_path)
			return
		end
	end
	neo_util.notify_error("Failed to fetch data from neovimcraft.com")
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
local function update_cache()
	local current_time = os.time()
	if not isCacheLoaded or (current_time - cache.last_update) > config.cache_refesh_rate then
		refresh_data()
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
		border = config.readme_window.border,
		title = opts.title,
		title_pos = "center",
	}

	local win = vim.api.nvim_open_win(buf, true, win_config)
	return { buf = buf, win = win }
end

-- Format plugin entry for display
---@param plugin Plugin
local function format_plugin(plugin)
	local name = plugin.id or "Unknown"
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

local function render_plugin_readme(plugin, opts)
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
	vim.keymap.set("n", config.key_bindings.close, function()
		vim.api.nvim_win_close(floating.win, true)
	end, { noremap = true, silent = true, buffer = floating.buf, desc = "Close floating window" })

	vim.keymap.set("n", "<esc>", function()
		vim.api.nvim_win_close(floating.win, true)
	end, { noremap = true, silent = true, buffer = floating.buf, desc = "Close floating window" })

	vim.keymap.set("n", config.key_bindings.open_git, function()
		vim.ui.open(plugin.link)
	end, { noremap = true, silent = true, buffer = floating.buf, desc = "Open plugin on GitHub" })

	vim.keymap.set("n", config.key_bindings.back_to_search, function()
		vim.api.nvim_win_close(floating.win, true)
		M.search_plugins(opts)
	end, { buffer = floating.buf, noremap = true, silent = true, desc = "Return to previous window" })
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
		neo_util.notify_error("No content to diplay")
		return
	end

	pickers
		.new(opts, {
			prompt_title = opts.tag and ("Neovimcraft Plugins [" .. opts.tag .. "]") or "Neovimcraft Plugins",
			default_text = opts.filter,
			finder = finders.new_table({
				results = content,
				---@param plugin Plugin
				entry_maker = function(plugin)
					return {
						value = plugin,
						display = format_plugin(plugin),
						ordinal = plugin.id,
					}
				end,
			}),
			sorter = sorters.get_fzy_sorter(opts),
			previewer = plugin_previewer,
			attach_mappings = function(prompt_bufnr, map)
				map("n", "<BS>", function(_prompt_bufnr)
					if opts.origin == "tags" then
						actions.close(_prompt_bufnr)
						opts.filter = opts.tag
						M.search_tags(opts)
					end
				end, { desc = "Return to previous window" })

				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					local prompt = action_state.get_current_line()
					actions.close(prompt_bufnr)
					local plugin = selection.value

					opts.filter = prompt or plugin.id
					render_plugin_readme(plugin, opts)
				end)
				return true
			end,
		})
		:find()
end

-- Main plugin search function
function M.search_by_tag(opts)
	opts = opts or {}
	update_cache()

	-- TODO: Implement search by tag
	local content = {}
	if not opts.tag then
		content = cache.plugins
	else
		for _, plugin in ipairs(cache.plugins) do
			for _, ptag in ipairs(plugin.tags) do
				if opts.tag == ptag then
					table.insert(content, plugin)
				end
			end
		end
	end
	plugin_picker(opts, content)
end

-- Main plugin search function
function M.search_plugins(opts)
	opts = opts or {}
	update_cache()

	local content = cache.plugins
	if not content then
		neo_util.notify_error("Failed to fetch data from nvim.sh")
		return
	end
	plugin_picker(opts, content)
end

-- List available tags
function M.search_tags(opts)
	opts = opts or {}
	update_cache()

	local content = cache.tags

	if not content then
		neo_util.notify_error("Failed to fetch data from nvim.sh")
		return
	end

	pickers
		.new(opts, {
			prompt_title = "Neovim Plugin Tags",
			default_text = opts.filter,
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
					opts.tag = selection.value
					opts.origin = "tags"
					opts.filter = ""
					M.search_by_tag(opts)
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
	if config.update_cache_at_start then
		update_cache()
	end
	if config.setup_user_commands then
		M.setup_user_commands()
	end
end

function M.setup_user_commands()
	vim.api.nvim_create_user_command(config.command_names.search_plugins, function(opts)
		update_cache()
		local args = opts.fargs
		if not args or #args == 0 then
			M.search_plugins(opts)
		else
			opts.filter = args[1]
			for _, plugin in ipairs(cache.plugins) do
				if plugin.id == args[1] then
					render_plugin_readme(plugin, opts)
					return
				end
			end
			plugin_picker(opts, cache.plugins)
		end
	end, {
		desc = "Search all plugins from Neovimcraft. Optionally search plugins by name",
		nargs = "?",
	})

	vim.api.nvim_create_user_command(config.command_names.search_tags, function(opts)
		update_cache()
		local args = opts.fargs
		local seach_term = args[1]
		if neo_util.array_contains(cache.tags, seach_term) then
			opts.tag = seach_term
			opts.origin = "tags"
			M.search_by_tag(opts)
		else
			opts.filter = seach_term
			M.search_tags(opts)
		end
	end, {
		desc = "List all tags from Neovimcraft. Optionally search plugins by tag",
		nargs = "?",
	})
end

return M
