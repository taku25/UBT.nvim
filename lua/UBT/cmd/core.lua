-- lua/UBT/cmd/core.lua (最新版・リファクタリング済み)

local unl_finder = require("UNL.finder")
local path = require("UBT.path")
local log = require("UBT.logger")

local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-------------------------------------------------
-- Process Checking (変更なし)
-------------------------------------------------
local function check_process_running_async(process_name, callback)
  local command
  if vim.fn.has("win32") == 1 then
    command = { "cmd", "/c", "tasklist | findstr " .. process_name }
  else
    command = { "sh", "-c", "ps aux | grep '[p]rocess_name'" }
    command[3] = command[3]:gsub("process_name", process_name)
  end
  vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_exit = function(_, exit_code)
      vim.schedule(function() callback(exit_code == 0) end)
    end,
  })
end

M.is_unreal_engine_busy = function(opts)
  opts = opts or {}
  local target_processes = opts.target_process or {}
  if #target_processes == 0 then
    if opts.on_finish then vim.schedule(function() opts.on_finish(false) end) end
    return
  end
  local processes_to_check = #target_processes
  local callback_fired = false
  for _, process_name in ipairs(target_processes) do
    local native_process_name = process_name
    if vim.fn.has("win32") == 1 and not native_process_name:find("%.exe$") then
      native_process_name = native_process_name .. ".exe"
    end
    check_process_running_async(native_process_name, function(is_running)
      if callback_fired then return end
      if is_running then
        callback_fired = true
        if opts.on_finish then opts.on_finish(true) end
        return
      end
      processes_to_check = processes_to_check - 1
      if processes_to_check == 0 and not callback_fired then
        callback_fired = true
        if opts.on_finish then opts.on_finish(false) end
      end
    end)
  end
end

-------------------------------------------------
-- Command Creation (新しいロジック)
-------------------------------------------------

function M.get_preset_from_label(label)
  for _, v in ipairs(get_config().presets or {}) do
    if v.name == label then return v end
  end
  return nil
end

local function create_label_target_args(uproject_path, label)
  local preset = M.get_preset_from_label(label)
  if not preset then return nil, "Preset not found: " .. tostring(label) end
  local project_name = vim.fn.fnamemodify(uproject_path, ":t:r")
  local target_name = preset.IsEditor and (project_name .. "Editor") or project_name
  log.get().info("Found build target: %s", target_name)
  return { target_name, preset.Platform, preset.Configuration }, nil
end

-- コマンドのベース部分（実行スクリプト + Engineパス）を作成するヘルパー
local function create_command_prefix(root_dir)
  local uproject_path, err = unl_finder.project.find_project_file(root_dir)
  if not uproject_path then return nil, nil, err end
  local engine_root, engine_err = unl_finder.engine.find_engine_root(uproject_path, {
    engine_override_path = get_config().engine_path,
  })
  if not engine_root then return nil, nil, engine_err end
  local script_path = path.get_ubt_launch_script_path()
  if not script_path then return nil, nil, "scripts/launch script not found." end

  local is_windows = vim.fn.has("win32") == 1
  local cmd_prefix
  if is_windows then
    cmd_prefix = { "cmd.exe", "/c", script_path, '"'..engine_root..'"' }
  else
    cmd_prefix = { script_path, engine_root }
  end
  
  return cmd_prefix, uproject_path, nil
end

function M.ensure_command_args(opts, mode)
  opts = opts or {}
  if not opts.root_dir then opts.root_dir = unl_finder.project.find_project_root(vim.loop.cwd()) end
  if not opts.root_dir then return nil, "Not inside a valid Unreal project." end
  if not opts.label then opts.label = get_config().preset_target end
  if not opts.label then return nil, "Not has label" end
  opts.mode = mode
  return opts, nil
end

-- ターゲット情報を含むコマンドを生成する (build, gencompiledb, genheader, lint用)
function M.create_command_with_target_platforms(opts, extra)
  local cmd_prefix, uproject_path, err = create_command_prefix(opts.root_dir)
  if err then return nil, err end

  local target_args, target_err = create_label_target_args(uproject_path, opts.label)
  if not target_args then return nil, target_err end
  
  -- 正しい順序で引数を組み立て
  local ubt_args = {}
  
  -- ▼▼▼ ここからが新しいロジック ▼▼▼
  local is_windows = vim.fn.has("win32") == 1


  vim.list_extend(ubt_args, target_args)

  -- 2. プロジェクトパスを追加
  if is_windows then
    table.insert(ubt_args, "-project=" .. '"' .. uproject_path .. '"')
  else
    table.insert(ubt_args, "-project=" .. uproject_path)
  end

  -- 3. モードを追加
  if opts.mode and opts.mode ~= "" then
    table.insert(ubt_args, "-mode=" .. opts.mode)
  end
  
  -- 4. その他の追加オプションを追加
  if extra then
    vim.list_extend(ubt_args, extra)
  end

  return vim.list_extend(cmd_prefix, ubt_args), nil
end

-- ターゲット情報を含まないコマンドを生成する (genproject用)
function M.create_command(root_dir, mode, extra_opts)
  local cmd_prefix, uproject_path, err = create_command_prefix(root_dir)
  if err then return nil, err end
  
  local ubt_args = {}
  if vim.fn.has("win32") == 1 then
    table.insert(ubt_args, "-project=" .. '"' .. uproject_path .. '"')
  else
    table.insert(ubt_args, "-project=" .. uproject_path)
  end

  if mode and mode ~= "" then
    table.insert(ubt_args, "-mode=" .. mode)
  end

  if extra_opts then
    vim.list_extend(ubt_args, extra_opts)
  end

  return vim.list_extend(cmd_prefix, ubt_args), nil
end

return M
