-- lua/UBT/cmd/core.lua (UNLベースにリファクタリング)

local unl_finder = require("UNL.finder")
local path = require("UBT.path") -- UBT固有のパスヘルパー（batのパス取得など）
local log = require("UBT.logger") -- UBT固有のパスヘルパー（batのパス取得など）

-- UNLの設定システムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-------------------------------------------------
-- Private Helper Functions
-------------------------------------------------

-- ラベル名からプリセット設定を取得する
local function get_preset_from_label(label)
  for _, v in ipairs(get_config().presets or {}) do
    if v.name == label then
      return v
    end
  end
  return nil
end

local function create_label_target_args(uproject_path, label)

  local preset = get_preset_from_label(label)
  if not preset then
    return nil, "Preset not found: " .. tostring(label)
  end
  local project_name = vim.fn.fnamemodify(uproject_path, ":t:r")
  local target_name = preset.IsEditor and (project_name .. "Editor") or project_name
  log.get().info("Found build target: %s", target_name)
  return { target_name, preset.Platform, preset.Configuration }, nil
end
-------------------------------------------------

function M.create_command(opts, mode, extra_opts)
  local uproject_path, err = unl_finder.project.find_project_file(opts.root_dir)
  if not uproject_path then
    return nil, err or "Could not find .uproject file."
  end

  local engine_root, engine_err = unl_finder.engine.find_engine_root(uproject_path, {
    engine_override_path = get_config().engine_path,
  })
  if not engine_root then
    return nil, engine_err or "Could not resolve Unreal Engine root."
  end

  local bat_path = path.get_ubt_lanch_bat_path()
  if not bat_path then
    return nil, "scripts/lunch.bat not found."
  end

  local cmd = {
    "cmd.exe", "/c", bat_path, '"'..engine_root..'"',
    "-project=" .. '"'..uproject_path..'"',
    "-Progress",
  }

  if mode then
    vim.list_extend(cmd, { "-mode=" .. mode })
  end
  if extra_opts then
    vim.list_extend(cmd, extra_opts)
  end

  return cmd, nil
end


function M.ensure_command_args(opts, mode)
  opts = opts or {}

  if not opts.root_dir then
    opts.root_dir = unl_finder.project.find_project_root(vim.loop.cwd())
  end

  -- それでも見つからなければエラー
  if not opts.root_dir then
    return nil, "Not inside a valid Unreal project."
  end

  if not opts.label then
    opts.label = require("UNL.config").get("UBT").preset_target
  end

  if not opts.label then
    return nil, "Not has label"
  end
  if not opts.mode then
    opts.mode = mode
  end

  return opts, nil
end

function M.create_command_with_target_platforms(opts, extra)
  local uproject_path, err = unl_finder.project.find_project_file(opts.root_dir)
  if not uproject_path then
    return nil, err
  end

  local target_args, target_err = create_label_target_args(uproject_path, opts.label)
  if not target_args then
    return nil, target_err
  end
  
  local final_opts = vim.list_extend(vim.deepcopy(target_args), extra or {})
  return M.create_command(opts.root_dir, opts.mode, final_opts)
end

return M
