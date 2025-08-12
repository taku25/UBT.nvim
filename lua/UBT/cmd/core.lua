-- UBT.nvim: Neovim command registration module
-- cmd.core.lua
local M = {}
local path = require("UBT.path")
local job = require("UBT.job.runner")
local logger = require("UBT.logger")

--- Extracts configuration details from a given label.
--- Returns a table containing target, platform, editor, and configuration.
local function get_config_from_label(root_dir, label)
  local conf = require("UBT.conf")
  for _, v in ipairs(conf.presets or {}) do
    if v.name == label then
      local project_name = path.get_project_name(path.find_uproject(root_dir))
      return {
        target = v.IsEditor and (project_name .. "Editor") or project_name,
        platform = v.Platform,
        configuration = v.Configuration,
        is_editor = v.IsEditor
      }
    end
  end
  logger.write ('No such config: ' .. tostring(label),  vim.log.levels.ERROR)
  return nil
end

function create_label_target_args(root_dir, label)
  local config_tbl = get_config_from_label(root_dir, label)

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
    logger.write("Unknown association type: " .. assoc, vim.log.levels.ERROR)
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
    logger.write("assoc is not a string: " .. tostring(assoc), vim.log.levels.ERROR)
    return nil
  end
  return M.detect_engine_association_type(assoc), assoc
end

--cr
function M.create_command(root_dir, mode, opts)
  local dir = root_dir
  local uproject = path.find_uproject(dir)
  if not uproject then
    logger.write('No uproject file found in: ' .. dir, vim.log.levels.ERROR)
    return nil
  end

  local project_fullpath = path.to_winpath_quoted(uproject)

  -- バッチ呼び出し（scripts/UBT_compile_commands.bat）
  local bat = path.to_winpath_quoted(path.get_ubt_lanch_bat_path())
  if not bat or vim.fn.filereadable(bat) == 0 then
    logger.write(' Launch bat not found.', vim.log.levels.ERROR)
    return nil
  end

  local assoc_type, assoc_value = M.get_engine_association_type_from_uproject(uproject)

  if assoc_type == "guid" then
    assoc_value = M.normalize_assoc(assoc_value)
  elseif assoc_type == "version" then
    assoc_value = assoc_value
  elseif assoc_type == "row" then
    assoc_value = '"' + assoc_value + '"'
  else
    logger.write('No EngineAssociation found in: ' .. uproject, vim.log.levels.ERROR)
    return nil
  end

  local core_cmd = {
    bat,
    assoc_type,
    assoc_value,
    "-project",
    project_fullpath,
    "-Progress",
  }


  local mode_cmd = {}
  if mode ~= nil then
    mode_cmd = {
      '-mode',
      mode,
    }
  end


  core_cmd = vim.list_extend(core_cmd, mode_cmd)

  return vim.list_extend(core_cmd, opts)
end

function M.create_command_with_target_platforms(root_dir, mode, label, opts)
  local core_cmd = M.create_command(root_dir, mode, {})
  if not core_cmd then
    return nil;
  end

  local cmd_target_args = create_label_target_args(root_dir, label)
  core_cmd = vim.list_extend(core_cmd, cmd_target_args)
  return vim.list_extend(core_cmd, opts)

end




return M

