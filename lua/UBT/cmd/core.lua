-- UBT.nvim: Neovim command registration module
-- cmd.core.lua
local M = {}
local util = require("UBT.util")
local job = require("UBT.job.runner")
local log = require("UBT.log")

--- Extracts configuration details from a given label.
--- Returns a table containing target, platform, editor, and configuration.
local function get_config_from_label(label)
  local conf = require("UBT.conf")
  for _, v in ipairs(conf.presets or {}) do
    if v.name == label then
      return {
        target = v.IsEditor and (util.get_project_name(util.find_uproject(vim.fn.getcwd())) .. "Editor") or util.get_project_name(util.find_uproject(vim.fn.getcwd())),
        platform = v.Platform,
        configuration = v.Configuration,
        is_editor = v.IsEditor
      }
    end
  end
  log.notify('No such config: ' .. tostring(label), vim.log.levels.ERROR, "no config")
  return nil
end

function create_label_target_args(label)
  local config_tbl = get_config_from_label(label)

  local args = {}
  if config_tbl then
    args = {
      config_tbl.target,
      config_tbl.platform,
      config_tbl.configuration,
    }
  end
  return args
end


--cr
function M.create_command(mode, opts)
  local dir = vim.fn.getcwd()
  local uproject = util.find_uproject(dir)
  if not uproject then
    log.notify('No uproject file found in: ' .. dir, vim.log.levels.ERROR)
    return
  end

  local project_fullpath = util.to_winpath_quoted(uproject)
  local project_root = util.to_winpath_quoted(util.get_project_root(uproject))

  -- バッチ呼び出し（scripts/UBT_compile_commands.bat）
  local bat = util.to_winpath_quoted(util.get_ubt_lanch_bat_path())
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
 }
  return vim.list_extend(core_cmd, opts)
end

function M.create_command_with_target_platforms(mode, label, opts)
  local core_cmd = M.create_command(mode, {})
  local cmd_target_args = create_label_target_args(label)

  core_cmd = vim.list_extend(core_cmd, cmd_target_args)

  return vim.list_extend(core_cmd, opts)

end

return M

