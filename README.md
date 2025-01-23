# Neovimcraft.nvim

Neovimcraft.nvim is a Neovim plugin designed to simplify the process of
discovering and exploring plugins from the [nvim.sh](https://nvim.sh) API
(see [neurosnap/neovimcraft](https://github.com/neurosnap/neovimcraft). It integrates
seamlessly with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim),
offering an intuitive interface for plugin and tag searches.

## Disclaimer

This plugin is **not an official plugin** for [neovimcraft.com](https://neovimcraft.com).
It is an independent project that utilizes the publicly available from neovimcraft.com
to fetch and display plugin data.
Special thanks to the team behind [neovimcraft.com](https://neovimcraft.com)
for providing such an excellent resource for the Neovim community and making
this API available.

[Eric Bower](https://bower.sh)
[Nvim.sh](https://github.com/neurosnap/nvim.sh)

## Table of Contents

<!--toc:start-->

- [Neovimcraft.nvim](#neovimcraftnvim)
  - [Features](#features)
  - [Requirements](#requirements)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Commands](#commands)
  - [Usage](#usage)
    - [Plugin Search](#plugin-search)
    - [Search Plugins by Tag](#search-plugins-by-tag)
  - [From Telescope Extension](#from-telescope-extension)
  - [Contributing](#contributing)
  <!--toc:end-->

## Features

- Search for plugins by name or tag.
- View detailed information about plugins, including stars, forks, and descriptions.
- Preview plugin README files in a floating window.
- Explore available tags to refine your searches.

## Requirements

- Neovim 0.9+ with Lua support.
- [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

Optional dependencies:

- [glow](https://github.com/charmbracelet/glow) - For enhanced README rendering in the terminal
- [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - Plugin to improve viewing Markdown files in Neovim (fallback for README rendering if glow is not installed)

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
return {
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

You can configure neovimcraft.nvim by passing a table to the setup function.
Below is the default configuration:

```lua
require('neovimcraft').setup({
    -- Path to store the cache. Data will be stored in a subdirectory called 'neovimcraft'
    cache_path = vim.fn.stdpath("cache"),
    -- If false, the cache will be updated on the first search
    update_cache_at_start = false,
    -- The window configuration for the readme preview
    readme_window = {
    -- The fraction of the editor's width
    width_ratio = 0.6,
    -- The fraction of the editor's height
    height_ratio = 0.8,
    -- Available options: 'none', 'single', 'double', 'rounded', etc.
    border = "double",
    },
    -- Enable or disable user auto commands
    setup_user_commands = true,
    -- User command name
    command_names = {
    search_plugins = "NeovimcraftPlugins", -- Command for plugin search
    search_tags = "NeovimcraftTags", -- Command for tag search
    },
    key_bindings = {
            close = "q", -- Key to close the preview window
            open_git = "o", -- Key to open GitHub link
            back_to_search = "<BS>", -- Key to go back to search results
    },
    -- How often to refresh the cache in seconds
    cache_refesh_rate = 24 * 3600, -- 24 hours
})
```

## Commands

If `setup_user_commands` is enabled, the following user commands are available
(unless you've customized the command names):

- `:NeovimcraftPlugins` – Search all plugins.
- `:NeovimcraftTags` – List all available tags.

## Usage

The plugin supports two different ways to render README files:

- If you have [glow](https://github.com/charmbracelet/glow) installed on your
  system, README files will be rendered with terminal markdown formatting for an
  enhanced viewing experience
- If `glow` is not available, the plugin will fallback to using your configured
  markdown LSP for syntax highlighting

### Plugin Search

You can search for plugins in several ways:

1. Basic search:

   ```vim
   :NeovimcraftPlugins  " Search all plugins available using Telescope
   :NeovimcraftTags     " Search all tags available using Telescope
   ```

2. Filtered search with arguments:

   ```vim
   :NeovimcraftPlugins lazy             " Search for plugins containing `lazy` as part of the `author/repo_name`
   :NeovimcraftPlugins folke/lazy.nvim  " Will open the plugin README in a floating window
   :NeovimcraftTags format              " Search for plugins with the `format` tag
   :NeovimcraftTags comp                " Search tags with `comp` as the filter input
   ```

3. Using Telescope directly:

   ```vim
   :Telescope neovimcraft plugins " Search all plugins available using Telescope
   ```

4. Select a plugin to view its details in a floating window.
5. In the floating window:

- Press `q` to close the window.
- Press `o` to open the plugin’s GitHub page.
- Press `<BS>` to navigate back to the previous Telescope window.

### Search Plugins by Tag

1. List all tags:

   ```vim
   :NeovimcraftTags
   ```

2. Select a tag to view plugins filtered by that tag.

## From Telescope Extension

If you’re using Telescope extensions, load the neovimcraft.nvim extension:

```lua
require('telescope').load_extension('neovimcraft')
```

You can then use the following Telescope functions:

- `:Telescope neovimcraft plugins` – Search plugins.
- `:Telescope neovimcraft tags` – Search tags.

## Contributing

Feel free to contribute by submitting issues, feature requests, or pull
requests. Ensure code follows best practices and is well-documented.

---

Enjoy discovering awesome Neovim plugins with Neovimcraft.nvim! 🚀
