# Neovimcraft.nvim

Neovimcraft.nvim is a Neovim plugin designed to simplify the process of discovering and exploring plugins from the [nvim.sh](https://nvim.sh) API. It integrates seamlessly with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), offering an intuitive interface for plugin and tag searches.

## Disclaimer

This plugin is **not an official plugin** for [neovimcraft.com](https://neovimcraft.com). It is an independent project that utilizes the publicly available [nvim.sh API](https://nvim.sh) to fetch and display plugin data.
Special thanks to the team behind [neovimcraft.com](https://neovimcraft.com) for providing such an excellent resource for the Neovim community and making this API available.

## Features

- Search for plugins by name or tag.
- View detailed information about plugins, including stars, forks, and descriptions.
- Preview plugin README files in a floating window.
- Explore available tags to refine your searches.

## Requirements

- Neovim 0.9+ with Lua support.
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Use your preferred plugin manager to install `neovimcraft.nvim`. For example:

### [Packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
    'janwvjaarsveld/neovimcraft.nvim',
    requires = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    config = function()
        require('neovimcraft').setup({
            -- Add your custom configuration here
        })
    end
}
```

### [Lazy](https://github.com/folke/lazy.nvim)

```lua
{
    'janwvjaarsveld/neovimcraft.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    config = function()
        require('neovimcraft').setup({
            -- Add your custom configuration here
        })
    end
}
```

## Configuration

You can configure neovimcraft.nvim by passing a table to the setup function. Below is the default configuration:

```lua
require('neovimcraft').setup({
    window = {
        width_ratio = 0.8, -- Fraction of the editor's width
        height_ratio = 0.8, -- Fraction of the editor's height
        border = "double", -- Window border style
    },
    setup_user_commands = false, -- Enable or disable user commands
    command_names = {
        plugin_seach = "NeovimcraftPlugins", -- Command for plugin search
        tag_seach = "NeovimcraftTags",      -- Command for tag search
    },
    key_bindings = {
        close = "q", -- Key to close the preview window
        open_git = "o", -- Key to open GitHub link
    },
	cache_ttl = { -- How long to cache API data in seconds
		plugins = 24 * 3600, -- 24 hours
		tags = 24 * 3600, -- 24 hours
	},
})
```

## Commands

If setup_user_commands is enabled, the following commands are available:
• :NeovimcraftPlugins – Search all plugins from nvim.sh.
• :NeovimcraftTags – List all available tags from nvim.sh.

## Usage

### Plugin Search

To search for plugins:

    1.	Open the Telescope picker with the user command:

```vim
:NeovimcraftPlugins
```

    2.	Select a plugin to view its details in a floating window.
    3.	In the floating window:
    •	Press q to close the window.
    •	Press o to open the plugin’s GitHub page.

### Search Plugins by Tag

    1.	List all tags:

```vim
:NeovimcraftTags
```

    2.	Select a tag to view plugins associated with it.

From Telescope Extension

If you’re using Telescope extensions, load the neovimcraft.nvim extension:

```lua
require('telescope').load_extension('neovimcraft')
```

You can then use the following Telescope functions:
• `:Telescope neovimcraft.seach_plugins` – Search plugins.
• `:Telescope neovimcraft.search_tags` – List tags.

## Screenshots

(Include screenshots of the plugin in action, such as plugin searches and previews.)

## Contributing

Feel free to contribute by submitting issues, feature requests, or pull requests. Ensure code follows best practices and is well-documented.

## License

## This plugin is licensed under the MIT License. See LICENSE for more details.

Enjoy discovering awesome Neovim plugins with Neovimcraft.nvim! 🚀
