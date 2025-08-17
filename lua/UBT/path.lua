-- UBT.nvim: Neovim command registration module
-- path.lua

local M = {}
local uv = vim.loop

local conf = require("UBT.conf")




--- ubp pluginディレクトリの取得
function M.find_ubt_plugin_root()
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if path:match("UBT.nvim") then
      return path
    end
  end
  return nil
end


function M.is_root_dir(root_dir)
  if M.find_uproject(root_dir) then
    return true
  end
  return false
end

function M.find_uproject(dir)
  local handle = uv.fs_scandir(dir)
  if not handle then return nil end
  while true do
    local name, t = uv.fs_scandir_next(handle)
    if not name then break end
    if t == 'file' and name:match('%.uproject$') then
      return dir .. '/' .. name
    end
  end
  return nil, "not found project file in " .. dir
end

--- uprojectファイルのパスからプロジェクト名（拡張子除去）を取得
function M.get_project_name(uproject_path)
  local filename = vim.fn.fnamemodify(uproject_path, ":t")
  return vim.fn.fnamemodify(filename, ":r")
end


--- lanch script batの取得
function M.get_ubt_lanch_bat_path()
  local root = M.find_ubt_plugin_root()
  return root and (root .. '/scripts/lunch.bat') or nil
end

--- 指定パスをバックスラッシュ区切りに変換し、ダブルクオートで囲む
function M.to_winpath_quoted(path)
  if type(path) ~= "string" then return path end

  -- スペースのエスケープを解除（"\ " → " "）
  path = path:gsub("\\ ", " ")

  -- \ を / に統一
  path = path:gsub("\\", "/")

  -- 絶対パス化
  path = vim.fn.fnamemodify(path, ":p")

  -- / を \ に変換
  path = path:gsub("\\", "/")


  return path
end

--- UBT.nvimのキャッシュディレクトリを取得し、なければ作成する
function M.get_cache_dir()
  -- nvimの標準的なキャッシュディレクトリのパスを取得
  local cache_dir = vim.fn.stdpath('cache')
  local ubt_cache_dir = cache_dir .. '/UBT'
  
  -- ディレクトリが存在しない場合は作成する
  -- vim.fn.isdirectory() はディレクトリなら1を返す
  if vim.fn.isdirectory(ubt_cache_dir) ~= 1 then
    -- 'p' オプションは、親ディレクトリもまとめて作成してくれる (mkdir -p と同じ)
    vim.fn.mkdir(ubt_cache_dir, 'p')
  end
  
  return ubt_cache_dir
end


function M.get_cache_dir()
  local cache_dir = vim.fn.stdpath('cache')
  local ubt_cache_dir = cache_dir .. '/UBT'
  if vim.fn.isdirectory(ubt_cache_dir) ~= 1 then
    vim.fn.mkdir(ubt_cache_dir, 'p')
  end
  return ubt_cache_dir
end

-- @param base string: ベースとなるディレクトリパス
-- @param name string: 結合したいファイルまたはディレクトリ名
-- @return string: 正しく結合されたパス
local function join_path(base, name)
  if not base or not name then return nil end
  -- Windowsかどうかを判定
  if vim.fn.has("win32") == 1 then
    -- Windowsの場合、末尾が \ でなければ \ を追加する
    if not base:match(".*\\$") then
      return base .. "\\" .. name
    end
    return base .. name
  else
    -- UnixライクなOSの場合、末尾が / でなければ / を追加する
    if not base:match(".*/$") then
      return base .. "/" .. name
    end
    return base .. name
  end
end
--- Checks a single directory for the existence of a .uproject file.
-- This is a private helper function.
-- @param dir string: The directory to check.
-- @return string|nil: The full path to the .uproject file if found, otherwise nil.
local function find_uproject_in_dir(dir)
  -- Use pcall for safety against permission errors etc.
  local ok, handle = pcall(vim.loop.fs_scandir, dir)
  if not ok or not handle then
    return nil
  end

  while true do
    local name, ftype = vim.loop.fs_scandir_next(handle)
    if not name then break end
    if ftype == 'file' and name:match('%.uproject$') then
      return join_path(dir, name)
    end
  end
  return nil
end


--- Searches upwards from a given path to find the project root directory.
-- The project root is defined as the directory containing a .uproject file.
-- @param start_path string: The file or directory path to start searching from.
-- @return string|nil: The absolute path to the project root directory if found.
-- @return string|nil: An error message if not found or on failure.
function M.find_project_root(start_path)
  local current_path = vim.fn.fnamemodify(start_path, ":p")
  if not current_path then
    return nil, "Invalid starting path provided."
  end

  if not vim.fn.isdirectory(current_path) then
    current_path = vim.fn.fnamemodify(current_path, ":h")
  end

  local previous_path = ""
  while current_path and current_path ~= previous_path do
    if find_uproject_in_dir(current_path) then
      return current_path, nil
    end
    previous_path = current_path
    current_path = vim.fn.fnamemodify(current_path, ":h")
  end

  return nil, "No .uproject file found in parent directories."
end


function M.get_log_file_path()
  return M .get_cache_dir() .. '/' .. conf.active_config.log_file_name
end

function M.get_progress_log_file_path()
  return M .get_cache_dir() .. '/' .. conf.active_config.progress_file_name
end

return M
