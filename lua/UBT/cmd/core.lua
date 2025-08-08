-- UBT.nvim: Neovim command registration module
-- cmd.core.lua
local M = {}
local util = require("UBT.util")
local job = require("UBT.job.runner")
local log = require("UBT.log")

--- compile_commands.json生成本体
function M.create_command(label, mode, opts)
  local dir = vim.fn.getcwd()
  local uproject = util.find_uproject(dir)
  if not uproject then
    log.notify('No uproject file found in: ' .. dir, vim.log.levels.ERROR)
    return
  end

  -- コンフィグ取得（例: config で name指定）
  local conf = require("UBT.conf")
  local config_tbl = nil
  for _, v in ipairs(conf.presets or {}) do
    if v.name == label then config_tbl = v break end
  end
  if not config_tbl then
    log.notify('No such config: ' .. tostring(label), vim.log.levels.ERROR, "no config")
    return
  end

  local project_fullpath = util.to_winpath_quoted(uproject)
  local project_name = util.get_project_name(uproject)
  local project_root = util.to_winpath_quoted(util.get_project_root(uproject))

  local platform = config_tbl.Platform
  local configuration = config_tbl.Configuration
  local is_editor = config_tbl.IsEditor
  local target = project_name .. (is_editor and "Editor" or "")

  -- バッチ呼び出し（scripts/UBT_compile_commands.bat）
  local balocal bat = util.to_winpath_quoted(util.get_ubt_lanch_bat_path())
  if not bat or vim.fn.filereadable(bat) == 0 then
    log.notify(' Launch bat not found.', vim.log.levels.ERROR, 'UBT Error')
    return
  end

  local assoc_type, assoc_value = util.get_engine_association_type_from_uproject(uproject)


  if assoc_type == "guid" then
    assoc_value = util.normalize_assoc(assoc_value)
  elseif assoc_type == "version" then
    assoc_value = assoc_value
  elseif assoc_type == "row" then
    assoc_value = '"' + assoc_value + '"'
  else
    log.notify('No EngineAssociation found in: ' .. uproject, vim.log.levels.ERROR)
    return
  end

  local core_cmd = {
    bat,
    assoc_type,
    assoc_value,
    mode,
    project_fullpath,
    project_root,
    "-Progress",
    "-game",
    "-engine",
    target,
    platform,
    configuration,
  }
  return vim.list_extend(core_cmd, opts)
end

return M


