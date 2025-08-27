# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image.png" /></div></td>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image-gen-compile-db.png" /></div></td>
  </tr>
</table>

`UBT.nvim` is a Neovim plugin that allows you to run Unreal Engine's Build, `compile_commands.json` generation, project file generation, and static analysis tasks directly from Neovim, asynchronously.

Check out the other plugins in the suite for enhancing Unreal Engine development: [`UEP.nvim`](https://github.com/taku25/UEP.nvim), [`UCM.nvim`](https://github.com/taku25/UCM.nvim).

[English](./README.md) | [日本語 (Japanese)](./README_ja.md)

---

## ✨ Features

*   **Asynchronous Execution**: Runs the Unreal Build Tool in the background using only native Neovim functionality (`vim.fn.jobstart`).
*   **Flexible Configuration System**: Built upon the powerful configuration system of `UNL.nvim`, allowing global settings as well as project-specific overrides via an `.unlrc.json` file in your project root.
*   **Rich UI Feedback**: Integrates with [fidget.nvim](https://github.com/j-hui/fidget.nvim) to display real-time build progress. (**Optional**)
*   **Unified UI Pickers**: Automatically detects and integrates with popular UI plugins like [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) and [fzf-lua](https://github.com/ibhagwan/fzf-lua) to provide a consistent user experience. (**Optional**)
    *   Fuzzy-find build errors and warnings, preview the location, and jump to the corresponding file and line with a single keypress.
    *   Select build targets from your familiar UI picker.
    *   The `fzf-lua` integration uses Lua coroutines, ensuring the UI remains responsive even when opening large diagnostic logs.

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
      Error searching with Telescope
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
      Error searching with fzf-lua
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

*   Neovim v0.9.0 or later
*   **[UNL.nvim](https://github.com/taku25/UNL.nvim)** (**Required**)
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**Optional**)
*   [fzf-lua](https://github.com/ibhagwan/fzf-lua) (**Optional**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**Optional**)
*   An environment where Unreal Build Tool is available (e.g., `dotnet` command).
*   Visual Studio 2022 (including the Clang toolchain).
*   Windows (Currently, testing has only been done on Windows).

## 🚀 Installation

Install using your favorite plugin manager.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

`UNL.nvim` is a required dependency. `lazy.nvim` will resolve this automatically.

```lua
-- lua/plugins/ubt.lua

return {
  'taku25/UBT.nvim',
  -- UBT.nvim depends on UNL.nvim.
  -- This line is usually not necessary as lazy.nvim resolves it automatically,
  -- but you can specify it explicitly.
  dependencies = { 'taku25/UNL.nvim' },
  
  -- If you use automation (autocmd), eager loading is recommended.
  -- lazy = false,
  
  opts = {
    -- Your configuration goes here (see below for details)
  }
}
```

## ⚙️ Configuration

You can customize the plugin's behavior by passing a table to the `setup()` function (or the `opts` table in `lazy.nvim`).
Below are all available options with their default values.

```lua
-- Inside your init.lua or opts = { ... } block for ubt.lua

{
  -- Preset definitions for build targets
  presets = {
    -- Default presets for Win64 are provided.
    -- You can add new presets or override existing ones.
    -- Example: { name = "LinuxShipping", Platform = "Linux", IsEditor = false, Configuration = "Shipping" },
  },

  -- Default target used when the target name is omitted in :UBT Build or :UBT GenCompileDB
  preset_target = "Win6d64DevelopWithEditor",

  -- Default linter type used when omitted in :UBT Lint
  lint_type = "Default",
  
  -- The engine path is usually detected automatically, but you can specify it explicitly here.
  engine_path = nil,

  -- The filename for the diagnostic log (errors and warnings)
  progress_file_name = "progress.log",

  -- ===== UI and Logging Settings (Inherited from UNL.nvim) =====
  
  -- Behavior of UI pickers (Telescope, fzf-lua, etc.)
  ui = {
    picker = {
      mode = "auto", -- "auto", "telescope", "fzf_lua", "native"
      prefer = { "telescope", "fzf_lua", "native" },
    },
    progress = {
      mode = "auto", -- "auto", "fidget", "window", "notify"
    },
  },

  -- Detailed logging configuration
  logging = {
    level = "info", -- Minimum level to write to the log file
    echo = { level = "warn" },
    notify = { level = "error", prefix = "[UBT]" },
    file = { 
      enable = true, 
      filename = "ubt.log", -- Main log file for the plugin
    },
  },
}
```

### Project-Specific Configuration

You can define project-specific settings by creating an `.unlrc.json` file in your project's root directory (where the `.uproject` file is located). These settings will override your global configuration.

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

Run the commands inside your Unreal Engine project directory.

```vim
:UBT Build[!] [target_name]            " Build the project. Use [!] to select a target from the UI picker.
:UBT GenCompileDB[!] [target_name]     " Generate compile_commands.json. Use [!] to open the UI picker.
:UBT Diagnostics                      " Display errors and warnings from the last build in the UI picker.
:UBT GenProject                     " Generate project files (e.g., for Visual Studio).
:UBT Lint [linter_type] [target_name] " Run static analysis.
```

### 💓 UI Picker Integration (Telescope / fzf-lua)

`UBT.nvim` automatically uses `telescope.nvim` or `fzf-lua` based on your configuration.

You can open the UI picker by running the `bang` version (`!`) of a command or by running the `Diagnostics` command.

*   `:UBT Build!`
*   `:UBT GenCompileDB!`
*   `:UBT Diagnostics`

## 🤖 API & Automation Examples

`UBT.nvim` provides a Lua API, which you can use with `autocmd` to streamline your development workflow.
For more details, check `:help ubt.txt`.

### 📂 Automatically `cd` to Project Root

Automatically change the current directory to the project root (where the `.uproject` file is) when you open a source file.

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

### 📰 Automatically Update Project Files on Save

Automatically run `:UBT GenProject` when you save a C++ header (`.h`) or source (`.cpp`) file.
**Note:** Hooking heavy tasks like builds can impact performance.

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

## See Also

Other Unreal Engine plugins:
*   [UEP.nvim](https://github.com/taku25/UEP.nvim) - Unreal Engine Project Manager
*   [UCM.nvim](https://github.com/taku25/UCM.nvim) - Unreal Engine Class Manager

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
