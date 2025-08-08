# UBT.nvim

UBT.nvim is a Neovim plugin that integrates with Unreal Build Tool (UBT) to facilitate operations like generating `compile_commands.json` and building Unreal Engine projects directly from Neovim.

## Features

- Generate `compile_commands.json` for Unreal Engine projects.
- Build Unreal Engine projects with specified configurations.
- Seamlessly integrates with Neovim's command system.
- Optionally integrates with [fidget.nvim](https://github.com/j-hui/fidget.nvim) for job progress visualization.

## Installation

Use [lazy.nvim](https://github.com/folke/lazy.nvim) to install UBT.nvim along with its dependency [fidget.nvim](https://github.com/j-hui/fidget.nvim):

```lua
require("lazy").setup({
  {
    "your-repo/UBT.nvim",
    dependencies = {
      "j-hui/fidget.nvim", -- Optional: For job progress visualization
    },
    config = function()
      require("UBT").setup {
        notify = true, -- Set to false to disable notifications.
        presets = {
          { name = "Win64Debug", Platform = "Win64", IsEditor = false, Configuration = "Debug" },
          { name = "Win64Develop", Platform = "Win64", IsEditor = false, Configuration = "Development" },
        },
        default = "Win64DevelopWithEditor", -- Default configuration to use.
      }
    end,
  }
})
```

## Platform Support

This plugin currently supports **Windows 11** only.

## Configuration

UBT.nvim can be configured by calling its `setup` function. Example configuration:

```lua
require('UBT').setup {
  notify = true, -- Set to false to disable notifications.
  presets = {
    { name = "Win64Debug", Platform = "Win64", IsEditor = false, Configuration = "Debug" },
    { name = "Win64Develop", Platform = "Win64", IsEditor = false, Configuration = "Development" },
    -- Add more build presets as needed.
  },
  default = "Win64DevelopWithEditor", -- Default configuration to use.
}
```

## Usage

**Note**: Make sure to run all commands from the root directory of your Unreal Engine project.

UBT.nvim provides the following commands:

### Generate Compile Commands

To generate `compile_commands.json` for your Unreal Engine project, run:

```vim
:UBT GenCompileDB
```

You can also specify a build configuration (e.g., `Win64Debug`):

```vim
:UBT GenCompileDB Win64Debug
```

If no configuration is specified, the default configuration from the setup will be used.

### Build

To build your Unreal Engine project with a specific configuration, run:

```vim
:UBT Build Win64Debug
```

## Dependencies

- Neovim 0.11.3 or newer.
- Unreal Build Tool (UBT).
- Optionally, [fidget.nvim](https://github.com/j-hui/fidget.nvim) for progress visualization.

## License

This plugin is licensed under the MIT License. See LICENSE for details.

