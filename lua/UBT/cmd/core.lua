-- UBT.nvim: Neovim command registration module
-- cmd.core.lua
local M = {}
local path = require("UBT.path")
local job = require("UBT.job.runner")
local logger = require("UBT.logger")
local conf = require("UBT.conf")

--- Extracts configuration details from a given label.
--- Returns a table containing target, platform, editor, and configuration.
local function get_config_from_label(root_dir, label)
  for _, v in ipairs(conf.active_config.presets or {}) do
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
  return nil, 'No such config: ' .. tostring(label)
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
    return nil, "Unknown association type: " .. assoc
  end
end

--- uprjectを読み込んでengine  associationを取得する
function M.get_engine_association_type_from_uproject(uproject_path)


  local content = vim.fn.readfile(uproject_path)
  local json = vim.fn.json_decode(table.concat(content, "\n"))

  local assoc = json and json.EngineAssociation
  assoc = tostring(assoc)

  if type(assoc) ~= "string" then
    return nil, nil, "assoc is not a string: " .. tostring(assoc)
  end
  return M.detect_engine_association_type(assoc), assoc, nil
end

--cr
function M.create_command(root_dir, mode, opts)
  local dir = root_dir
  local uproject, error = path.find_uproject(dir)
  if error ~= nil then
    return nil, error
  end

  local project_fullpath = path.to_winpath_quoted(uproject)

  -- バッチ呼び出し（scripts/UBT_compile_commands.bat）
  local bat = path.to_winpath_quoted(path.get_ubt_lanch_bat_path())
  if not bat or vim.fn.filereadable(bat) == 0 then
    return nil, ' Launch bat not found.'
  end



  local final_assoc_type = nil
  local final_assoc_value = nil

  --値が入っていたらそちらを優先
  if conf.active_config.engine_path ~= nil and not conf.active_config.engine_path ~= "" then
    
    final_assoc_type = "row" -- 直接パスを指定するので、タイプは "row" になる
    final_assoc_value = conf.active_config.engine_path
  else
    local uproj_type, uproj_value, err = M.get_engine_association_type_from_uproject(uproject)
    if err ~= nil then
      return nil, err
    end
    final_assoc_type = uproj_type
    final_assoc_value = uproj_value
  end



  if final_assoc_type == "guid" then
    final_assoc_value = M.normalize_assoc(final_assoc_value)
  elseif final_assoc_type == "version" then
    final_assoc_value = final_assoc_value
  elseif final_assoc_type == "row" then
    final_assoc_value = '"' .. final_assoc_value .. '"'
  else
    return nil, 'No EngineAssociation found in: ' .. uproject
  end

  local core_cmd = {
    bat,
    final_assoc_type,
    final_assoc_value,
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

  return vim.list_extend(core_cmd, opts), nil
end

function M.create_command_with_target_platforms(root_dir, mode, label, opts)
  local core_cmd, error = M.create_command(root_dir, mode, {})
  if error ~= nil then
    return nil, error
  end

  local cmd_target_args = create_label_target_args(root_dir, label)
  core_cmd = vim.list_extend(core_cmd, cmd_target_args)
  return vim.list_extend(core_cmd, opts), nil

end




return M

