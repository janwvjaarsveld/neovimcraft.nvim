# `Neovimcraft.nvim`

`Neovimcraft.nvim` is a Neovim plugin designed to simplify the process of
discovering and exploring plugins from the [nvim.sh](https://nvim.sh) API
(see [neurosnap/neovimcraft](https://github.com/neurosnap/neovimcraft)). It integrates
seamlessly with [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim),
offering an intuitive interface for plugin and tag searches.

## Disclaimer

This plugin is **not an official plugin** for [neovimcraft.com](https://neovimcraft.com).
It is an independent project that utilizes the publicly available API from neovimcraft.com
to fetch and display plugin data.
Special thanks to the team behind [neovimcraft.com](https://neovimcraft.com)
for providing such an excellent resource for the Neovim community and making
this API available.

## Table of Contents

<!--toc:start-->

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Commands](#commands)
- [Usage](#usage)
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
}
```

### [Lazy](https://github.com/folke/lazy.nvim)

```lua
return {
    'janwvjaarsveld/neovimcraft.nvim',
    dependencies = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    -- Calling setup is not required if you are happy with the default configuration
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
    -- If true, the cache will be checked and updated when the plugin is loaded
    -- If false, the cache will be checked and updated on the first search
    update_cache_at_startup = false,
    -- Enable or disable glow for README rendering
    use_glow = true,
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
    setup_user_autocmds = true,
    -- User command name
    command_names = {
        -- Command for plugin search
        search_plugins = "NeovimcraftPlugins",
        -- Command for tag search
        search_tags = "NeovimcraftTags",
    },
    key_bindings = {
        -- Key to close the preview window
        close = "q",
        -- Key to open GitHub link
        open_git = "o",
        -- Key to go back to search results
        back_to_search = "<BS>",
    },
    -- How often to refresh the cache in seconds
    cache_refesh_rate = 24 * 3600, -- 24 hours
})
```

## Commands

If `setup_user_commands` is enabled, the following user autocommands are available
(unless you've customized the command names):

- `:NeovimcraftPlugins` – Search all plugins.
- `:NeovimcraftTags` – Search all tags.

## Usage

The plugin supports two different ways to render README files:

- If you have [glow](https://github.com/charmbracelet/glow) installed on your
  system, README files will be rendered with terminal markdown formatting for an
  enhanced viewing experience
- If `glow` is not available, the plugin will fallback to using your configured
  markdown LSP for syntax highlighting

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

3. Using Telescope extension:

   ```lua
   require('telescope').load_extension('neovimcraft')
   ```

   You can then use the following Telescope functions:

   ```vim
   :Telescope neovimcraft plugins   " Search all plugins available using Telescope
   :Telescope neovimcraft tags      " Search all tags available using Telescope
   ```

4. Select a plugin to view its details in a floating window.
5. In the floating window:

   - Press `q` to close the window.
   - Press `o` to open the plugin’s GitHub page.
   - Press `<BS>` to navigate back to the previous Telescope window.

## Contributing

Feel free to contribute by submitting issues, feature requests, or pull
requests. Ensure code follows best practices and is well-documented.

## I don't see my plugin in the search results

If you don't see your plugin in the search results, it may be that the plugin
is not yet submitted to [neovimcraft.com](https://neovimcraft.com). You can
submit your plugin by following the instructions [here](https://github.com/neurosnap/neovimcraft?tab=readme-ov-file#want-to-submit-a-plugin)

## Credits

- [Eric Bower](https://bower.sh) - Creator of [neovimcraft.com](https://neovimcraft.com)
- [Nvim.sh](https://github.com/neurosnap/nvim.sh) - API for [neovimcraft.com](https://neovimcraft.com)

---

Enjoy discovering awesome Neovim plugins with Neovimcraft.nvim! 🚀
