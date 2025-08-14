# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image.png" /></div></td>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image-gen-compile-db.png" /></div></td>
  </tr>
</table>

`UBT.nvim` は、Unreal Engine のcompile_commands.json、Build、GenerateProject、静的解析などの機能を、Neovimから直接、非同期で実行するためのプラグインです。

[English](./README.md) | [日本語](./README_ja.md)

---

## ✨ 機能 (Features)

*   **非同期実行**: 純粋なneovimの機能で非同期でunreal build Toolをバックグラウンドで実行します。
*   **柔軟な設定システム**:
    *   グローバル設定に加え、プロジェクトルートに `.ubtrc` ファイルを置くことで、プロジェクト固有の設定を自動で読み込みます。
*   **リッチなUIフィードバック**: [fidget.nvim](https://github.com/j-hui/fidget.nvim) と連携し、リアルタイムでビルドの進捗を表示します。(**オプション**)
*   **対話的なエラーブラウジング**: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) との連携(**オプション**)
    *   ビルドエラーやワーニングをTelescopeでファジー検索。
    *   エラー箇所をプレビューし、Enterキー一発で該当ファイル・行へジャンプ。
    *   ビルドターゲットや`compile_commands.json`生成ターゲットをTelescopeから選択して実行

<table>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build.gif" />
      UBT Build コマンド
    </div>
  </td>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-gencompile-db.gif" />
      UBT GenCompileDB コマンド
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-telescope-diagnostics.gif" />
      UBT Build と Telescope でエラー検索
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/telescope-build-select.gif" />
     Telescope からUBT Build コマンド
    </div>
    </td>
  </tr>
</table>

## 🔧 必要要件 (Requirements)

*   Neovim v0.11.3 以上
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**オプション**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**オプション**)
*   Unreal Build Tool が利用可能な環境 (`dotnet` コマンドなど)
*   Visual Studio 2022とVisual Studio Installerからインストールされたclang
*   Windows環境でのみサポート(その他のOSは環境がなくて対応できていませんが環境ができれば対応する予定)

## 🚀 インストール (Installation)

お使いのプラグインマネージャーでインストールしてください。

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- plugins/ubt.lua

return {
  'taku25/UBT.nvim',
  dependencies = {
      "j-hui/fidget.nvim",(オプション)
  },
  opt = {},
}
```

Note: Telescope拡張を有効にするために、Telescope側の設定で UBT.nvim を依存関係に追加し、load_extension してください

```lua
-- plugins/ubt.lua
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


## ⚙️ 設定 (Configuration)
Setup 関数にテーブルを渡すことで、プラグインの挙動をカスタマイズできます。 lazyでプラグインをインストールしている場合はoptsに書いてください
以下は、すべてのオプションと、そのデフォルト値です。

```lua
-- init.lua や ubt.lua の config ブロック内

opts = {
  -- ビルドターゲットの定義プリセット
  presets = {
    -- 用意されているプリセットは
    --  Win64DebugGame, Win64Develop, Win64Shipping, 
    --  Win64DebugGameWithEditor, Win64DevelopWithEditor
    -- になります
    -- 新しいプリセットを追加したり既存のものを上書きする場合は下記のように書いてください
    -- 上書き
    { name = "Win64DevelopWithEditor", Platform = "Win64", IsEditor = true, Configuration = "Development" },
    -- 追加
    { name = "StreamOSShipping", Platform = "Stream", IsEditor = false, Configuration = "Shipping" },
  },

  -- :UBT Build や :UBT GenCompileDB で、引数が省略された際に使われるデフォルトのターゲット名
  preset_target = "Win64DevelopWithEditor",

  -- :UBT Lint で、引数が省略された際に使われるデフォルトのlinter type
  -- Default
  -- VisualCpp
  -- PVSStudio
  -- Clang
  -- 各タイプの違いはUnrealBuildToolのドキュメントを確認してください
  lint_type = "Default",
  
  -- UBT.nvimの基本の動作は.uproject を読み込み EngineAssociation を使用し
  -- 自動でUnreal Build Toolを検索しますが
  -- エンジンパスを明示的に指定したい場合に使用してください
  -- 例: "C:/Program Files/Epic Games/UE_5.4"
  engine_path = nil,

  -- === ログと通知の設定 ===

  -- notifyが、どのレベルのメッセージを通知として表示するか
  -- vim.notifyが実行されます
  -- "NONE", "ERROR", "WARN", "ALL"
  notify_level = "NONE",

  -- unreal build toolを実行中の出力がどのレベルで表示するか
  -- fidget.nvimの通知が実行されます
  -- "NONE", "ERROR", "WARN", "ALL"
  progress_level = "ALL",


  -- Messageがどのレベルで表示するか
  -- vim.echoが実行されますのでmessageで見ることができます
  -- "NONE", "ERROR", "WARN", "ALL"
  message_level = "ERROR",

  -- ログファイルの名前 (nvimのキャッシュディレクトリ内に作成されます)
  -- neovim cache dir + ubt(dir) + logfile_name
  log_file_name = "diagnostics.log",   -- UBT.nvimの全ログ
  progress_file_name = "progress.log", -- 最新のunreal build tool実行ログ

  -- fidget.nvim の表示をカスタマイズするかどうか
  -- lsptype UBTとして内部でカスタマイズしています
  -- ユーザ設定を使用する場合は falseにして
  -- fidget.nvimのoptsでlsp UBTのスタイルを変更してください
  enable_override_fidget = true,

  -- vim.jobが動作するShell 現在はcmdのみ対応
  -- powershellからneovimを起動してもlunch.batは指定したシェルで起動します
  shell = "cmd",
})
```


## ⚙️ プロジェクト固有の設定 (.ubtrc) 
ルートディレクトリ（UBT コマンド実行時のneovimのカレントディレクトリ）に .ubtrc という名前のJSONファイルを作成することで、そのプロジェクトだけで有効な設定を定義できます。
.ubtrc の設定は、グローバルな setup() 設定よりも優先されます。
.ubtrc の例:
```JSON
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
## ⚡ 使い方 (Usage)

**neovimで.uprojectがあるディレクトリに移動してからコマンドを実行してください**


``` viml
:UBT GenCompileDB [ターゲット名]     " compile_commands.json を生成します。
:UBT Build [ターゲット名]            " 指定されたターゲット（またはデフォルト）でプロジェクトをビルドします。
:UBT GenProject                     " Visual Studioなどのプロジェクトファイルを生成します。
:UBT Lint [linterタイプ] [ターゲット名] " 静的解析を実行します。
``` 

## 🤖 API & 自動化 (Automation Examples)

`UBT.nvim` は、Lua APIを提供しているため、`autocmd`と組み合わせることで、開発ワークフローを少し楽にできます。
すべてのAPIはdocumentで確認してください
```viml
:help ubt
```

### 📂 プロジェクトルートへ移動(auto cd)
Unreal Engineのソースファイルを開いたとき、自動的にそのファイルのプロジェクトルート（`.uproject`があるディレクトリ）にカレントディレクトリを変更します

```lua
-- init.lua or any setup file

local ubt_auto_cd_group = vim.api.nvim_create_augroup("UBT_AutoCD", { clear = true })

vim.api.nvim_create_autocmd("BufEnter", {
  group = ubt_auto_cd_group,
  pattern = { "*.cpp", "*.h", "*.hpp", "*.cs" },
  callback = function(args)
    local ok, ubt_api = pcall(require, "UBT.api")
    if not ok then
      return
    end
    -- プロジェクトルートを検索
    local project_root, err = ubt_api.find_project_root(args.file)

    if project_root and project_root ~= vim.fn.getcwd() then
      vim.cmd.cd(project_root)
    end
  end,
})
```

### 📰 保存時のプロジェクト更新(auto make projct)

C++ヘッダーファイル (`.h`) やソースファイル (`.cpp`) を保存した際に、自動的に `:UBT GenProject` を実行します。
APIをつかってファイル保存時にビルドすることもできますが、**パフォーマンスに影響を与える可能性があります。**

  <div align=center><img width="50%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/auto-cmd-gen-project.gif" /></div>

```lua
-- init.lua or any setup file

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

### 🔭 Telescope連携 

``` viml
:Telescope ubt diagnostics          " 直近のジョブ実行で発生した情報を一覧表示します
:Telescope ubt build                " 設定されているビルドターゲットを一覧表示し、選択するだけでビルドを開始できます
:Telescope ubt gencompiledb         " ビルドターゲットを選択し、compile_commands.jsonの生成を開始します。
```

## 📜 ライセンス (License)
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
