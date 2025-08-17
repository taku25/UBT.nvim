# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image.png" /></div></td>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image-gen-compile-db.png" /></div></td>
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
*   **fzf-lua 💓 UBT.nvim**: Integrates with [fzf-lua](https://github.com/ibhagwan/fzf-lua) to provide functionality similar to the Telescope integration (**Optional**).
    *   The fzf-lua integration uses **Lua coroutines** to ensure the UI remains responsive, even when opening large diagnostics logs.

<table>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build.gif" />
      UBT Build Command
    </div>
  </td>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-gencompile-db.gif" />
      UBT GenCompileDB Command
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-telescope-diagnostics.gif" />
      UBT Build And Telescope UI Search Build Error
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/telescope-build-select.gif" />
     UBT Build Command on Telescope UI
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua-diagnostics.gif" />
      UBT Build And fzf-lua UI Search Build Error
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua.gif" />
     UBT Build Command on fzf-lua UI
    </div>
    </td>
  </tr>
</table>

## 🔧 Requirements

*   Neovim v0.11.3 or higher
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**Optional**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**Optional**)
*   [fzf-lua](https://github.com/ibhagwan/fzf-lua) (**Optional**)
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
> **Note:** To ensure the fzf-lua integration loads correctly, it's recommended to define `UBT.nvim` as a dependency of `fzf-lua`. This guarantees that the picker modules are available when you define commands or keymaps.

```lua
{
  "ibhagwan/fzf-lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "taku25/UBT.nvim",
  },
  config = function(_, opts)
    -- It's good practice to run the plugin's setup function first
    require("fzf-lua").setup(opts)

    -- Define user commands after setup
    vim.api.nvim_create_user_command("UBTFzfBuild",
      function() require("fzf-lua.ubt").build.exec() end,
      { desc = "UBT: Open fzf picker to select a build target", nargs = 0 }
    )
    vim.api.nvim_create_user_command("UBTFzfGenCompileDB",
      function() require("fzf-lua.ubt").gen_compile_db.exec() end,
      { desc = "UBT: Open fzf picker to generate compile_commands.json", nargs = 0 }
    )
    vim.api.nvim_create_user_command("UBTFzfDiagnostics",
      function() require("fzf-lua.ubt").diagnostics.exec() end,
      { desc = "UBT: Open fzf to view process logs", nargs = 0 }
    )

    -- It's cleaner to map to the commands you just created
    vim.keymap.set('n', '<leader>ub', '<cmd>UBTFzfBuild<cr>', { desc = "UBT: Build (fzf)" })
    vim.keymap.set('n', '<leader>uc', '<cmd>UBTFzfGenCompileDB<cr>', { desc = "UBT: Compile DB (fzf)" })
    vim.keymap.set('n', '<leader>ud', '<cmd>UBTFzfDiagnostics<cr>', { desc = "UBT: Diagnostics (fzf)" })
  end
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
    --  Win64DebugGame, Win64Develop, Win64Shipping, 
    --  Win64DebugGameWithEditor, Win64DevelopWithEditor
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
## 🤖 API & Automation Examples

`UBT.nvim` provides a Lua API that you can combine with `autocmd` to streamline your development workflow.
See the help document for a full API reference:
```viml
:help ubt
You can add the following recipes to your init.lua or a dedicated autocommand file.
```

### 📂 Auto CD to Project Root ###
Automatically change the current directory to the project root (the directory containing the .uproject file) whenever you open an Unreal Engine source file. This ensures that :UBT commands are always run from the correct location.

```Lua
-- in init.lua or any setup file

local ubt_auto_cd_group = vim.api.nvim_create_augroup("UBT_AutoCD", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = ubt_auto_cd_group,
  pattern = { "*.cpp", "*.h", "*.hpp", "*.cs" },
  callback = function(args)
    local ok, ubt_api = pcall(require, "UBT.api")
    if not ok then
      return
    end
    -- Find the project root
    local project_root, err = ubt_api.find_project_root(args.file)

    if project_root and project_root ~= vim.fn.getcwd() then
      vim.cmd.cd(project_root)
    end
  end,
})
```

### 📰 Auto Generate Project on Save ###
Automatically run :UBT GenProject whenever you save a C++ header (.h) or source (.cpp) file.
While you can also use the API to trigger a build on save, please be aware that this can have performance implications.
   
  <div align=center><img width="50%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/auto-cmd-gen-project.gif" /></div>
  

```Lua
-- in init.lua or any setup file

local ubt_auto_build_group = vim.api.nvim_create_augroup("UBT_AutoBuildOnSave", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = ubt_auto_build_group,
  pattern = { "*.cpp", "*.h", "*.hpp" },
  callback = function(args)
    local ok, ubt_api = pcall(require, "UBT.api")
    if not ok then
      return
    end

    local project_root, _ = ubt_api.find_project_root(args.file)
    if not project_root then
      return
    end
    
    ubt_api.gen_project()
  end,
})
```

### 🔭 Telescope Integration 

```viml
:Telescope ubt diagnostics          " Lists information from the last job run.
:Telescope ubt build                " Lists configured build targets and starts a build on selection.
:Telescope ubt gencompiledb         " Select a build target to start generating compile_commands.json.
```
  
### 💓 fzf-lua Integration

You can use the provided functions to freely define your own commands and keymaps for launching the fzf-lua pickers.

#### Command Definitions

It's recommended to create user commands to easily access the pickers. You can place this code anywhere that runs after startup (e.g., in your `init.lua` or a dedicated setup file).

```lua
-- Define user commands for fzf-lua pickers
vim.api.nvim_create_user_command( "UBTFzfBuild",
  function() require("fzf-lua.ubt").build.exec() end,
  { desc = "UBT: Open fzf picker to select a build target", nargs = 0 }
)
vim.api.nvim_create_user_command("UBTFzfGenCompileDB",
  function() require("fzf-lua.ubt").gen_compile_db.exec() end,
  { desc = "UBT: Open fzf picker to generate compile_commands.json", nargs = 0 }
)
vim.api.nvim_create_user_command("UBTFzfDiagnostics",
  function() require("fzf-lua.ubt").diagnostics.exec() end,
  { desc = "UBT: Open fzf to view process logs", nargs = 0 }
)
```

#### Keymaps

Once the commands are defined, you can easily map them to your preferred keys.

```lua
-- Example keymaps
vim.keymap.set('n', '<leader>ub', '<cmd>UBTFzfBuild<cr>', { desc = "UBT: Build Target (fzf)" })
vim.keymap.set('n', '<leader>uc', '<cmd>UBTFzfGenCompileDB<cr>', { desc = "UBT: Gen Compile DB (fzf)" })
vim.keymap.set('n', '<leader>ud', '<cmd>UBTFzfDiagnostics<cr>', { desc = "UBT: Diagnostics (fzf)" })
```

#### Usage

After setting up, you can use the commands directly or via your keymaps:

```viml
:UBTFzfDiagnostics          " Lists diagnostics from the last job execution.
:UBTFzfBuild                " Lists configured build targets and starts a build upon selection.
:UBTFzfGenCompileDB         " Select a build target to start generating compile_commands.json.
```

## Others
Neovim plugin link for Unreal Engine
* 	[UCM.nvim](https://github.com/taku25/UCM.nvim) — Unreal Engine Class Manager.

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
