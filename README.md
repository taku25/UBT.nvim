# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><img width="100%" alt="image" src="https://github.com/user-attachments/assets/edb41521-11c7-4ceb-a2f8-1b316f3d4893" /></td>
   <td><img width="100%" alt="image" src="https://github.com/user-attachments/assets/be138d48-e172-4591-b34d-679776636124" /></td>
  </tr>
</table>

`UBT.nvim` is a plugin that allows you to run Unreal Engine's features like `compile_commands.json` generation, builds, project file generation, and static analysis directly from Neovim, asynchronously.

[**English**](./README.md) | [Japanese](./README_ja.md)

---

## ✨ Features

*   **Asynchronous Execution**: Runs the Unreal Build Tool in the background asynchronously using Neovim's native job control.
*   **Flexible Configuration System**: In addition to global settings, automatically loads project-specific configurations from a `.ubtrc` file in the project root.
*   **Rich UI Feedback**: (Optional) Integrates with [fidget.nvim](https://github.com/j-hui/fidget.nvim) to display real-time build progress.
*   **Interactive Error Browsing**: (Optional) Powerful integration with [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).
    *   Fuzzy find through build errors and warnings.
    *   Preview the code location of an error and jump to the file and line with a single keypress.
    *   Select build targets or `compile_commands.json` generation targets directly from a Telescope picker.

<table>
   <tr>
      <td>
         <div align="center">
   <img width="70%" alt="image" src="https://github.com/user-attachments/assets/0f5b50f5-a27e-4ace-a1e1-66897cf055b8" /><br>
      build error and telescope search error
         </div>
      </td>
      <td>
          <div align="center">
   <img width="70%" alt="image" src="https://github.com/user-attachments/assets/aa504bfc-2848-4316-92e5-99af2c8d97a9" /><br>
      telescope select build target
          </div>
      </td>
   </tr>
</table>

## 🔧 Requirements

*   Neovim v0.11.3 or higher
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**Optional**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**Optional**)
*   An environment where Unreal Build Tool is usable (`dotnet` command, etc.).
*   Visual Studio 2022 with the Clang compiler component installed via the Visual Studio Installer.
*   Currently only supports the Windows environment. Support for other OSes is planned once I have access to the necessary environments.

## 🚀 Installation

Install with your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- plugins/ubt.lua

return {
  'taku25/UBT.nvim',
  dependencies = {
      "j-hui/fidget.nvim", -- (Optional)
  },
  opts = {},
}
```

> **Note**: To enable the Telescope extension, it is recommended to add `UBT.nvim` as a dependency in your Telescope configuration and load the extension.

```lua
-- plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = { "taku25/UBT.nvim" },
  config = function()
    local telescope = require("telescope")
    telescope.setup({ /* ... */ })
    telescope.load_extension("ubt")
  end,
}
```

## ⚙️ Configuration
You can customize the plugin's behavior by passing a table to the `setup()` function. If you are using `lazy.nvim`, pass this table to the `opts` key.
The following shows all available options and their default values.

```lua
-- in your init.lua or config block for the plugin

opts = {
  -- Pre-defined build targets.
  presets = {
    -- The available built-in presets are:
    --  Win64Debug, Win64DebugGame, Win64Develop, Win64Test, Win64Shipping, 
    --  Win64DebugWithEditor, Win64DebugGameWithEditor, Win64DevelopWithEditor
    -- To add new presets or override existing ones, write as follows:
    -- Override an existing preset
    { name = "Win64DevelopWithEditor", Platform = "Win64", IsEditor = true, Configuration = "Development" },
    -- Add a new preset
    { name = "StreamOSShipping", Platform = "Stream", IsEditor = false, Configuration = "Shipping" },
  },

  -- The default target name used when the argument is omitted for :UBT Build or :UBT GenCompileDB.
  preset_target = "Win64DevelopWithEditor",

  -- The default linter type for :UBT Lint.
  -- Available options: Default, VisualCpp, PVSStudio, Clang
  -- For the differences between each type, please check the UnrealBuildTool documentation.
  lint_type = "Default",
  
  -- UBT.nvim's basic operation is to read the .uproject file and use EngineAssociation
  -- to automatically find the Unreal Build Tool. Use this option if you want to
  -- explicitly specify the engine path.
  -- Example: "C:/Program Files/Epic Games/UE_5.4"
  engine_path = nil,

  -- === Logging and Notification Settings ===

  -- Determines which message level is displayed as a notification (uses `vim.notify`).
  -- Available options: "NONE", "ERROR", "WARN", "ALL"
  notify_level = "NONE",

  -- Determines which output level from the running Unreal Build Tool is displayed (uses `fidget.nvim`).
  -- Available options: "NONE", "ERROR", "WARN", "ALL"
  progress_level = "ALL",

  -- Determines which message level is displayed in the message area (uses `vim.echo`).
  -- Available options: "NONE", "ERROR", "WARN", "ALL"
  message_level = "ERROR",

  -- Log file names (created within Neovim's cache directory).
  -- Format: <neovim cache dir>/UBT/<logfile_name>
  log_file_name = "diagnostics.log",   -- Persistent log for all UBT.nvim activity
  progress_file_name = "progress.log", -- Temporary log for the latest UBT run

  -- Whether to customize the fidget.nvim display.
  -- This plugin internally customizes the LSP type "UBT".
  -- If you want to use your own settings, set this to false and configure
  -- the style for LSP type "UBT" in your fidget.nvim opts.
  enable_override_fidget = true,

  -- The shell used to run `vim.job`. Currently, only "cmd" is supported.
  -- Even if you start Neovim from PowerShell, lunch.bat will be started with the specified shell.
  shell = "cmd",
}
```

## ⚙️ Project-Specific Settings (.ubtrc) 
You can define settings that are only active for a specific project by creating a JSON file named `.ubtrc` in the project's root directory (the current directory of Neovim when you run a UBT command).
`.ubtrc` settings take precedence over global `setup()` settings.

Example `.ubtrc`:
```json
{
  "preset_target": "StreamOS",
  "engine_path": "C:/Program Files/Epic Games/UE_5.6",
  "presets": [
    {
      "name": "StreamOSTest",
      "Platform": "Win64",
      "IsEditor": true,
      "Configuration": "Test"
    },
    {
      "name": "StreamOSShipping",
      "Platform": "Stream",
      "IsEditor": false,
      "Configuration": "Shipping"
    }
  ]
}
```

## ⚡ Usage

**Please `cd` into the directory containing your `.uproject` file before executing commands.**

```viml
:UBT GenCompileDB [target_name]     " Generates compile_commands.json.
:UBT Build [target_name]            " Builds the project with the specified (or default) target.
:UBT GenProject                     " Generates project files for Visual Studio, etc.
:UBT Lint [linter_type] [target_name] " Runs static analysis.
``` 

### 🔭 Telescope Integration 

```viml
:Telescope ubt diagnostics          " Lists information from the last job run.
:Telescope ubt build                " Lists configured build targets and starts a build on selection.
:Telescope ubt gencompiledb         " Select a build target to start generating compile_commands.json.
```

## 📜 License
MIT License

Copyright (c) 2025 taku25

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
