# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image.png" /></div></td>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image-gen-compile-db.png" /></div></td>
  </tr>
</table>

`UBT.nvim` is a plugin to asynchronously execute Unreal Engine tasks such as building, header generation (UHT), `compile_commands.json` generation, project file generation, and static analysis directly from Neovim.


[English](./README.md) | [日本語](./README_ja.md)

---

## ✨ Features

*   **Asynchronous Execution**: Runs Unreal Build Tool asynchronously in the background using only Neovim's native functions (`vim.fn.jobstart`).
*   **Build Conflict Dialog**: When a build is already running, `:UBT build` shows a `vim.ui.select` "Restart build?" dialog instead of silently failing. If Unreal Engine is already running (detected via `tasklist`), a second "Build anyway?" dialog is shown.
*   **Build Summary**: On build completion, a summary is logged: e.g., `Build succeeded in 12s (0 errors, 3 warnings)` or `Build FAILED in 8s (5 errors, 2 warnings)`.
*   **Elapsed Time**: All build/compile/gen operations report elapsed time on completion (e.g., `Compile DB generated in 45s`).
*   **Flexible Configuration System**:
    *   Based on the powerful configuration system of `UNL.nvim`, allowing project-specific settings via a `.unlrc.json` file in the project root to override global settings.
*   **Rich UI Feedback**: Integrates with [fidget.nvim](https://github.com/j-hui/fidget.nvim) to display real-time build progress. (**Optional**)
*   **Unified UI Picker**: Automatically detects popular UI plugins like [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and [fzf-lua](https://github.com/ibhagwan/fzf-lua) to provide a consistent user experience. (**Optional**)
    *   Fuzzy search for build errors and warnings, preview them, and jump to the corresponding file and line with a single key press.
    *   Select build targets from your familiar UI picker.
    *   The integration with `fzf-lua` uses Lua coroutines, preventing the UI from freezing even when opening large diagnostic logs.
*   **Accelerated by Incremental Updates**: Automatically detects the manifest file (`.uhtmanifest`) when running the Unreal Header Tool (`GenHeader`) to perform incremental updates for faster header generation.

<table>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build.gif" />
      UBT Build command
    </div>
  </td>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-gencompile-db.gif" />
      UBT GenCompileDB command
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-telescope-diagnostics.gif" />
      Search errors with Telescope
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/telescope-build-select.gif" />
     Select build target from Telescope
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua-diagnostics.gif" />
      Search errors with fzf-lua
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua.gif" />
      Select build target with fzf-lua
    </div>
    </td>
  </tr>
</table>

## 🔧 Requirements

*   Neovim v0.11.3 or later
*   **[UNL.nvim](https://github.com/taku25/UNL.nvim)** (**Required**)
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**Optional**)
*   [fzf-lua](https://github.com/ibhagwan/fzf-lua) (**Optional**)
*   [snacks.nvim](https://github.com/folke/snacks.nvim) (**Optional**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**Optional**)
*   An environment where Unreal Build Tool is available (e.g., `dotnet` command)
*   Visual Studio 2022 (including the Clang toolchain)
*   Windows (Operation on other operating systems is not currently tested)

## 🚀 Installation

Install with your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

`UNL.nvim` is a required dependency. `lazy.nvim` will resolve this automatically.

```lua
-- lua/plugins/ubt.lua

return {
  'taku25/UBT.nvim',
  -- UBT.nvim depends on UNL.nvim.
  -- This line is usually not necessary as lazy.nvim resolves it automatically.
  dependencies = { 'taku25/UNL.nvim' },
  
  -- If you use autocmd (automation), eager loading is recommended.
  -- lazy = false,
  
  opts = {
    -- Add your settings here (details below)
  }
}```

## ⚙️ Configuration

You can customize the plugin's behavior by passing a table to the `setup()` function (or to `opts` in `lazy.nvim`).
Below are all the available options with their default values.

```lua
-- Inside init.lua or opts = { ... } for ubt.lua

{
  -- Presets for build target definitions
  presets = {
    -- Presets for Win64 are provided by default.
    -- You can add your own presets or override existing ones.
    -- e.g., { name = "LinuxShipping", Platform = "Linux", IsEditor = false, Configuration = "Shipping" },
  },

  -- Default target when target name is omitted in :UBT Build or :UBT GenCompileDB
  preset_target = "Win64DevelopWithEditor",

  -- Default linter type when omitted in :UBT Lint
  lint_type = "Default",
  
  -- Usually auto-detected, but you can use this to explicitly specify the engine path
  engine_path = nil,

  -- Filename for UBT to write diagnostic logs (errors and warnings)
  progress_file_name = "progress.log",

  -- ===== Automation Settings =====
  automation = {
    -- When true, automatically runs :LspRestart after a successful gen_compile_db
    restart_lsp_after_gen_compile_db = false,
    -- When true, automatically runs gen_header after a lightweight refresh
    auto_gen_header_after_lightweight_refresh = false,
    -- When true, automatically generates project files after gen_header succeeds
    auto_gen_project_after_gen_header_success = false,
    -- When true, automatically generates project files after a full refresh
    auto_gen_project_after_refresh_completed  = false,
  },

  -- ===== UI and Logging Settings (Inherited from UNL.nvim) =====
  
  -- Behavior settings for UI pickers (Telescope, fzf-lua, etc.)
  ui = {
    picker = {
      mode = "auto", -- "auto", "telescope", "fzf_lua", "native"
      prefer = { "telescope", "fzf_lua", "native" },
    },
    progress = {
      mode = "auto", -- "auto", "fidget", "window", "notify"
    },
  },

  -- Detailed logging settings
  logging = {
    level = "info", -- Minimum level to write to the log file
    echo = { level = "warn" },
    notify = { level = "error", prefix = "[UBT]" },
    file = { 
      enable = true, 
      filename = "ubt.log", -- Log file for the entire plugin's operations
    },
  },
}
```

### Project-Specific Configuration

You can define settings that are only active for a specific project by creating a JSON file named `.unlrc.json` in the project's root directory (where the `.uproject` file is located). These settings will take precedence over global settings.

Example: `.unlrc.json`
```json
{
  "preset_target": "LinuxShipping",
  "engine_path": "D:/UE_Custom/UE_5.4_Linux",
  "presets": [
    {
      "name": "LinuxShipping",
      "Platform": "Linux",
      "IsEditor": false,
      "Configuration": "Shipping"
    }
  ]
}
```

## ⚡ Usage

Run the commands within an Unreal Engine project directory.

```vim
:UBT build[!] [target_name]                 " Builds the project. Use [!] to launch the UI picker.
:UBT run[!]                                 " Runs the project. Use [!] to launch the UI picker. It automatically selects the correct executable (e.g., UnrealEditor-Win64-DebugGame.exe) based on the chosen configuration.
:UBT gen_header[!] [target_name] [module_name] " Runs the Unreal Header Tool. Use [!] for UI picker. Module name is optional.
:UBT gen_compile_db[!] [target_name]          " Generates compile_commands.json. Use [!] to launch the UI picker.
:UBT diagnostics                           " Displays errors and warnings from the last build in the UI picker.
:UBT genProject                            " Generates project files for Visual Studio, etc.
:UBT lint [linter_type] [target_name]         " Runs static analysis.
:UBT cancel_build                          " Cancels the currently running build job.
```

### 💓 UI Picker Integration (Telescope / fzf-lua)

`UBT.nvim` automatically uses `telescope.nvim` or `fzf-lua` according to your setup.

The UI picker can be opened by running the `bang` version (`!`) of the following commands, or by using the `Diagnostics` command.

  * `:UBT build!`
  * `:UBT run!`
  * `:UBT gen_header!`
  * `:UBT gen_compile_db!`
  * `:UBT diagnostics`

## 🤖 API & Automation (Automation Examples)

`UBT.nvim` provides a Lua API, allowing you to streamline your development workflow by combining it with `autocmd`.
For more details, see `:help ubt.txt`.

### 📂 Automatically change to the project root

When you open an Unreal Engine source file, this automatically changes the current directory to the project root of that file (the directory containing the `.uproject` file).

```lua
-- init.lua or any setup file
local ubt_auto_cd_group = vim.api.nvim_create_augroup("UBT_AutoCD", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", {
  group = ubt_auto_cd_group,
  pattern = { "*.cpp", "*.h", "*.hpp", "*.cs" },
  callback = function(args)
    local ok, ubt_api = pcall(require, "UBT.api")
    if not (ok and ubt_api) then return end
    
    local project_root = ubt_api.find_project_root(args.file)
    if project_root and project_root ~= vim.fn.getcwd() then
      vim.cmd.cd(project_root)
    end
  end,
})
```

### 📰 Automatically update project files on save

Automatically runs `:UBT GenProject` when you save a C++ header (`.h`) or source (`.cpp`) file.
**Note:** Hooking heavy processes like building can impact performance.

<div align=center><img width="50%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/auto-cmd-gen-project.gif" /></div>

```lua
-- init.lua or any setup file
local ubt_auto_gen_proj_group = vim.api.nvim_create_augroup("UBT_AutoGenerateProject", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  group = ubt_auto_gen_proj_group,
  pattern = { "*.cpp", "*.h", "*.hpp" },
  callback = function()
    local ok, ubt_api = pcall(require, "UBT.api")
    if not (ok and ubt_api) then return end
    
    if ubt_api.find_project_root(vim.fn.getcwd()) then
      ubt_api.gen_project()
    end
  end,
})
```

## Others

**Unreal Engine Related Plugins:**

  * [**UnrealDev.nvim**](https://github.com/taku25/UnrealDev.nvim)
      * **Recommended:** An all-in-one suite to install and manage all these Unreal Engine related plugins at once.
  * [**UNX.nvim**](https://github.com/taku25/UNX.nvim)
      * **Standard:** A dedicated explorer and sidebar optimized for Unreal Engine development. It visualizes project structure, class hierarchies, and profiling insights without depending on external file tree plugins.
  * [UEP.nvim](https://github.com/taku25/UEP.nvim)
      * Analyzes .uproject to simplify file navigation.
  * [UEA.nvim](https://github.com/taku25/UEA.nvim)
      * Finds Blueprint usages of C++ classes.
  * [UBT.nvim](https://github.com/taku25/UBT.nvim)
      * Use Build, GenerateClangDataBase, etc., asynchronously from Neovim.
  * [UCM.nvim](https://github.com/taku25/UCM.nvim)
      * Add or delete classes from Neovim.
  * [ULG.nvim](https://github.com/taku25/ULG.nvim)
      * View UE logs, LiveCoding, stat fps, etc., from Neovim.
  * [USH.nvim](https://github.com/taku25/USH.nvim)
      * Interact with ushell from Neovim.
  * [USX.nvim](https://github.com/taku25/USX.nvim)
      * Plugin for highlight settings for tree-sitter-unreal-cpp and tree-sitter-unreal-shader.
  * [neo-tree-unl](https://github.com/taku25/neo-tree-unl.nvim)
      * Integration for [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) users to display an IDE-like project explorer.
  * [tree-sitter for Unreal Engine](https://github.com/taku25/tree-sitter-unreal-cpp)
      * Provides syntax highlighting using tree-sitter, including UCLASS, etc.
  * [tree-sitter for Unreal Engine Shader](https://github.com/taku25/tree-sitter-unreal-shader)
      * Provides syntax highlighting for Unreal Shaders like .usf, .ush.
    
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
