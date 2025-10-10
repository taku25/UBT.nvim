-- lua/UBT/path.lua (UNLベースにリファクタリング)

-- UNLのコアモジュールをインポート
local unl_cache_core = require("UNL.cache.core")

-- UNLの設定システムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-- このプラグイン自身のルートパスをキャッシュする変数
local ubt_plugin_root_path

---
-- UBT.nvimプラグインのルートディレクトリを探して返す
-- @return string|nil
function M.find_ubt_plugin_root()
  if ubt_plugin_root_path then
    return ubt_plugin_root_path
  end
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if path:match("[/\\]UBT.nvim$") then
      ubt_plugin_root_path = path
      return path
    end
  end
  return nil
end

---
-- 実行するlunch.batスクリプトのフルパスを取得する
-- @return string|nil
function M.get_ubt_launch_script_path()
  local root = M.find_ubt_plugin_root()
  if not root then
    return nil
  end

  -- OSを判定
  local is_windows = vim.fn.has("win32") == 1
  local script_name = is_windows and "launch.bat" or "launch.sh"
 
  local script_path = vim.fs.joinpath(root, "scripts", script_name)

  -- 念のためファイルの存在を確認
  if vim.fn.filereadable(script_path) == 1 then
    return script_path
  end
 
  return nil
end
---
-- .uprojectファイルのパスからプロジェクト名（拡張子なし）を取得する
-- @param uproject_path string
-- @return string
function M.get_project_name(uproject_path)
  return vim.fn.fnamemodify(uproject_path, ":t:r")
end

---
-- パスをWindows形式に正規化し、クオートで囲む（バッチファイル用）
-- @param path string
-- @return string
-- function M.to_winpath_quoted(path)
--   if type(path) ~= "string" then return path end
--   local normalized = vim.fn.fnamemodify(path, ":p"):gsub("\\", "/")
--   return '"' .. normalized .. '"'
-- end

---
-- UBT.nvimのメインログファイルのフルパスを取得する
-- @return string
function M.get_log_file_path()
  local conf = get_config()
  local base_dir = unl_cache_core.get_cache_dir(conf)
  local filename = conf.log_file_name or "ubt.log" -- デフォルトファイル名
  return vim.fs.joinpath(base_dir, filename)
end

---
-- UBT.nvimの進捗ログファイル（Telescope/fzf-lua用）のフルパスを取得する
-- @return string
function M.get_progress_log_file_path()
  local conf = get_config()
  local base_dir = unl_cache_core.get_cache_dir(conf)
  local filename = conf.progress_file_name or "progress.log" -- デフォルトファイル名
  return vim.fs.joinpath(base_dir, filename)
end

return M
