-- UBT.nvim: Neovim command registration module
-- util.lua

local M = {}
local uv = vim.loop

local log = require("UBT.log")

--- uprojectファイルをディレクトリから検出
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
  return nil
end

--- uprojectファイルのパスからプロジェクト名（拡張子除去）を取得
function M.get_project_name(uproject_path)
  local filename = vim.fn.fnamemodify(uproject_path, ":t")
  return vim.fn.fnamemodify(filename, ":r")
end

--- uprojectファイルのディレクトリパスを取得
function M.get_project_root(uproject_path)
  return vim.fn.fnamemodify(uproject_path, ":p:h")
end



--- ubp pluginディレクトリの取得
function M.find_ubt_plugin_root()
  for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
    if path:match("UBT.nvim") then
      return path
    end
  end
  return nil
end


-- is unreal root dir (is contain )
function M.is_root_dir()
  if M.find_uproject(vim.fn.getcwd()) then
    return true
  end
  return false
end

--- erase {}
function M.normalize_assoc(assoc)
    return assoc:gsub("^%{", ""):gsub("%}$", "")
end

--- uprojectから読み込んだengine associationのタイプを取得する
function M.detect_engine_association_type(assoc)
  -- Accept GUID with or without curly braces

  assoc = assoc:match("^%s*(.-)%s*$") -- trim whitespace

  local x = "%x"
  local t = { x:rep(8), x:rep(4), x:rep(4), x:rep(4), x:rep(12) }
  local pattern = table.concat(t, '%-')

  local pattern_plain = "^" .. pattern .. "$"
  local pattern_curly = "^{" .. pattern .. "}$"

  if assoc:match(pattern_plain) or assoc:match(pattern_curly) then
    return "guid"
  elseif assoc:match("^%d+%.%d+$") or assoc:match("^UE_%d+%.%d+$") then
    return "version"
  elseif assoc:match("^%a:[\\/].+") then
    return "row"
  else
    log.notify("Unknown association type: " .. assoc, vim.log.levels.ERROR)
    return nil
  end
end
--- uprjectを読み込んでengine  associationを取得する
function M.get_engine_association_type_from_uproject(uproject_path)
  local content = vim.fn.readfile(uproject_path)
  local json = vim.fn.json_decode(table.concat(content, "\n"))

  local assoc = json and json.EngineAssociation
  assoc = tostring(assoc)

  if type(assoc) ~= "string" then
    log.notify("assoc is not a string: " .. tostring(assoc), vim.log.levels.ERROR)
    return nil
  end
  return M.detect_engine_association_type(assoc), assoc
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
  path = path:gsub("/", "\\")

  return path
end

return M
