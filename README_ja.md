# UBT.nvim

# Unreal Build Tool 💓 Neovim

<table>
  <tr>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image.png" /></div></td>
   <td><div align=center><img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/main-image-gen-compile-db.png" /></div></td>
  </tr>
</table>

`UBT.nvim` は、Unreal Engine のビルド、ヘッダー生成（UHT）、`compile_commands.json` 生成、プロジェクトファイル生成、静的解析といった機能を、Neovimから直接、非同期で実行するためのプラグインです。

Unreal プラグイン群
* [UEP.nvim](https://github.com/taku25/UEP.nvim)
  * urpojectを解析してファイルナビゲートなどを簡単に行えるようになります
* [UBT.nvim](https://github.com/taku25/UBT.nvim)
  * BuildやGenerateClangDataBaseなどを非同期でNeovim上から使えるようになります
* [UCM.nvim](https://github.com/taku25/UCM.nvim)
  * クラスの追加や削除がNeovim上からできるようになります。
* [ULG.nvim](https://github.com/taku25/ULG.nvim)
  * UEのログやliveCoding,stat fpsなどnvim上からできるようになります
* [USH.nvim](https://github.com/taku25/USH.nvim)
  * ushellをnvimから対話的に操作できるようになります
* [neo-tree-unl](https://github.com/taku25/neo-tree-unl.nvim)
  * IDEのようなプロジェクトエクスプローラーを表示できます。
* [tree-sitter for Unreal Engine](https://github.com/taku25/tree-sitter-unreal-cpp)
  * UCLASSなどを含めてtree-sitterの構文木を使ってハイライトができます

[English](./README.md) | [日本語](./README_ja.md)

---

## ✨ 機能 (Features)

*   **非同期実行**: Neovimの標準機能（`vim.fn.jobstart`）のみを使用し、Unreal Build Toolをバックグラウンドで非同期に実行します。
*   **柔軟な設定システム**:
    *   `UNL.nvim` の強力な設定システムをベースにしており、グローバル設定に加え、プロジェクトルートの `.unlrc.json` ファイルによるプロジェクト固有設定の上書きが可能です。
*   **リッチなUIフィードバック**: [fidget.nvim](https://github.com/j-hui/fidget.nvim) と連携し、リアルタイムでビルドの進捗を表示します。(**オプション**)
*   **統一されたUIピッカー**: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) や [fzf-lua](https://github.com/ibhagwan/fzf-lua) といった人気のUIプラグインを自動で認識し、統一された操作感を提供します。(**オプション**)
    *   ビルドエラーや警告をファジー検索し、プレビューで確認後、Enterキー一発で該当ファイル・行へジャンプできます。
    *   ビルドターゲットの選択も、使い慣れたUIピッカーから行えます。
    *   `fzf-lua` との連携ではLuaコルーチンを使用しており、サイズの大きな診断ログを開いてもUIが固まりません。
*   **差分更新による高速化**: Unreal Header Tool (`GenHeader`) 実行時にマニフェストファイル (`.uhtmanifest`) を自動で検出し、差分更新を利用して高速なヘッダー生成を実現します。

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
      Telescope でエラー検索
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/telescope-build-select.gif" />
     Telescope からビルドターゲットを選択
    </div>
    </td>
  </tr>
  <tr>
   <td>
    <div align=center>
      <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua-diagnostics.gif" />
      fzf-lua でエラー検索
    </div>
   </td>
   <td>
   <div align=center>
    <img width="100%" alt="image" src="https://raw.githubusercontent.com/taku25/UBT.nvim/images/assets/ubt-build-fzf-lua.gif" />
      fzf-lua でビルドターゲットを選択
    </div>
    </td>
  </tr>
</table>

## 🔧 必要要件 (Requirements)

*   Neovim v0.11.3 以上
*   **[UNL.nvim](https://github.com/taku25/UNL.nvim)** (**必須**)
*   [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (**オプション**)
*   [fzf-lua](https://github.com/ibhagwan/fzf-lua) (**オプション**)
*   [fidget.nvim](https://github.com/j-hui/fidget.nvim) (**オプション**)
*   Unreal Build Tool が利用可能な環境 (`dotnet` コマンドなど)
*   Visual Studio 2022 (Clangツールチェインを含む)
*   Windows (現在、他のOSでの動作確認は行っていません)

## 🚀 インストール (Installation)

お使いのプラグインマネージャーでインストールしてください。

### [lazy.nvim](https://github.com/folke/lazy.nvim)

`UNL.nvim` が必須の依存関係です。`lazy.nvim` はこれを自動で解決します。

```lua
-- lua/plugins/ubt.lua

return {
  'taku25/UBT.nvim',
  -- UBT.nvim は UNL.nvim に依存しています。
  -- lazy.nvim が自動で解決するため、通常はこの行は不要です。
  dependencies = { 'taku25/UNL.nvim' },
  
  -- もしautocmd（自動化）を使う場合は、即時読み込みを推奨します。
  -- lazy = false,
  
  opts = {
    -- ここに設定を記述します (詳細は後述)
  }
}
```

## ⚙️ 設定 (Configuration)

`setup()` 関数（または `lazy.nvim` の `opts`）にテーブルを渡すことで、プラグインの挙動をカスタマイズできます。
以下は、すべてのオプションと、そのデフォルト値です。

```lua
-- init.lua や ubt.lua の opts = { ... } の中身

{
  -- ビルドターゲットの定義プリセット
  presets = {
    -- デフォルトで Win64 用のプリセットが用意されています。
    -- 独自のプリセットを追加したり、既存の設定を上書きできます。
    -- 例: { name = "LinuxShipping", Platform = "Linux", IsEditor = false, Configuration = "Shipping" },
  },

  -- :UBT Build や :UBT GenCompileDB でターゲット名を省略した際のデフォルト
  preset_target = "Win64DevelopWithEditor",

  -- :UBT Lint でlinterタイプを省略した際のデフォルト
  lint_type = "Default",
  
  -- 通常は自動検出されますが、エンジンのパスを明示的に指定したい場合に使用します
  engine_path = nil,

  -- UBTが診断ログ（エラーや警告）を書き出すファイル名
  progress_file_name = "progress.log",

  -- ===== UIとロギング設定 (UNL.nvimから継承) =====
  
  -- UIピッカー（Telescope, fzf-luaなど）の挙動設定
  ui = {
    picker = {
      mode = "auto", -- "auto", "telescope", "fzf_lua", "native"
      prefer = { "telescope", "fzf_lua", "native" },
    },
    progress = {
      mode = "auto", -- "auto", "fidget", "window", "notify"
    },
  },

  -- ログ出力の詳細設定
  logging = {
    level = "info", -- ログファイルに書き込む最低レベル
    echo = { level = "warn" },
    notify = { level = "error", prefix = "[UBT]" },
    file = { 
      enable = true, 
      filename = "ubt.log", -- プラグイン全体の動作ログ
    },
  },
}
```

### プロジェクト固有の設定

プロジェクトのルートディレクトリ（`.uproject`ファイルがある場所）に `.unlrc.json` という名前のJSONファイルを作成することで、そのプロジェクトだけで有効な設定を定義できます。この設定は、グローバルな設定よりも優先されます。

例: `.unlrc.json`
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

## ⚡ 使い方 (Usage)

コマンドは、Unreal Engineプロジェクトのディレクトリ内で実行してください。

```vim
:UBT build[!] [ターゲット名]                " プロジェクトをビルドします。[!]付きでUIピッカーを起動します。
:UBT run[!]                                 " プロジェクトを実行します。[!]付きでUIピッカーを起動すると、選択された構成（DebugGameなど）に合わせて適切な実行ファイル（例: UnrealEditor-Win64-DebugGame.exe）を自動判定して起動します。
:UBT gen_ueader[!] [ターゲット名] [モジュール名] " Unreal Header Toolを実行します。[!]付きでUIピッカーを起動。モジュール名はオプションです。
:UBT gen_uompile_db[!] [ターゲット名]         " compile_commands.json を生成します。[!]付きでUIピッカーを起動します。
:UBT diagnostics                          " 直近のビルドで発生したエラーや警告をUIピッカーで表示します。
:UBT gen_project                           " Visual Studioなどのプロジェクトファイルを生成します。
:UBT lint [linterタイプ] [ターゲット名]        " 静的解析を実行します。
```

### 💓 UIピッカー連携 (Telescope / fzf-lua)

`UBT.nvim`は、設定に応じて `telescope.nvim` や `fzf-lua` を自動で利用します。

UIピッカーは、以下のコマンドの `bang` 版 (`!`) を実行するか、`Diagnostics` コマンドを実行することで開くことができます。

  * `:UBT build!`
  * `:UBT run!`
  * `:UBT gen_header!`
  * `:UBT gen_compile_db!`
  * `:UBT diagnostics`

## 🤖 API & 自動化 (Automation Examples)

`UBT.nvim` は、Lua APIを提供しているため、`autocmd`と組み合わせることで、開発ワークフローを効率化できます。
詳細は `:help ubt.txt` で確認してください。

### 📂 プロジェクトルートへ自動で移動

Unreal Engineのソースファイルを開いたとき、自動的にカレントディレクトリをそのファイルのプロジェクトルート（`.uproject`があるディレクトリ）に変更します。

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

### 📰 保存時にプロジェクトファイルを自動更新

C++ヘッダーファイル (`.h`) やソースファイル (`.cpp`) を保存した際に、自動的に `:UBT GenProject` を実行します。
**注意:** ビルドなどの重い処理をフックすると、パフォーマンスに影響を与える可能性があります。

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

## その他

Unreal Engine 関連プラグイン:

  * [**UnrealDev.nvim**](https://github.com/taku25/UnrealDev.nvim)
      * **推奨:** これら全てのUnreal Engine関連プラグインを一括で導入・管理できるオールインワンスイートです。
  * [**UNX.nvim**](https://github.com/taku25/UNX.nvim)
      * **標準搭載:** Unreal Engine開発に特化した専用のエクスプローラー＆サイドバーです。Neo-tree等に依存せず、プロジェクト構造、クラス概形、プロファイリング結果などを表示できます。
  * [UEP.nvim](https://github.com/taku25/UEP.nvim)
      * .uprojectを解析してファイルナビゲートなどを簡単に行えるようになります。
  * [UEA.nvim](https://github.com/taku25/UEA.nvim)
      * C++クラスがどのBlueprintアセットから使用されているかを検索します。
  * [UBT.nvim](https://github.com/taku25/UBT.nvim)
      * BuildやGenerateClangDataBaseなどを非同期でNeovim上から使えるようになります。
  * [UCM.nvim](https://github.com/taku25/UCM.nvim)
      * クラスの追加や削除がNeovim上からできるようになります。
  * [ULG.nvim](https://github.com/taku25/ULG.nvim)
      * UEのログやLiveCoding, stat fpsなどをNeovim上から操作できるようになります。
  * [USH.nvim](https://github.com/taku25/USH.nvim)
      * ushellをNeovimから対話的に操作できるようになります。
  * [USX.nvim](https://github.com/taku25/USX.nvim)
      * tree-sitter-unreal-cpp や tree-sitter-unreal-shader のハイライト設定などを補助するプラグインです。
  * [neo-tree-unl](https://github.com/taku25/neo-tree-unl.nvim)
      * もし [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) をお使いの場合は、こちらを使うことでIDEのようなプロジェクトエクスプローラーを表示できます。
  * [tree-sitter for Unreal Engine](https://github.com/taku25/tree-sitter-unreal-cpp)
      * UCLASSなどを含めてtree-sitterの構文木を使ってハイライトができます。
  * [tree-sitter for Unreal Engine Shader](https://github.com/taku25/tree-sitter-unreal-shader)
      * .usfや.ushなどのUnreal Shader用のシンタックスハイライトを提供します。


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
