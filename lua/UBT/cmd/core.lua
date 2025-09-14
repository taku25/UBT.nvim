-- lua/UBT/cmd/core.lua (UNLベースにリファクタリング)

local unl_finder = require("UNL.finder")
local path = require("UBT.path") -- UBT固有のパスヘルパー（batのパス取得など）
local log = require("UBT.logger") -- UBT固有のパスヘルパー（batのパス取得など）

-- UNLの設定システムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

--- process_name が実行中か非同期でチェックする
-- @param process_name string: チェックしたいプロセス名
-- @param callback fun(is_running: boolean): チェック完了後に呼ばれるコールバック関数
local function check_process_running_async(process_name, callback)
  local command
  if vim.fn.has("win32") == 1 then
    -- Windowsの場合: tasklist の結果を findstr で絞り込む
    -- findstr は見つかった場合に exit code 0 を返す
    command = { "cmd", "/c", "tasklist | findstr " .. process_name }
  else
    -- macOS/Linuxの場合: ps の結果を grep で絞り込む
    -- grep は見つかった場合に exit code 0 を返す
    command = { "sh", "-c", "ps aux | grep '[p]rocess_name'" }
    -- [p]rocess_name のように書くと、grep自身のプロセスがヒットしなくなるので `grep -v grep` が不要になる
    command[3] = command[3]:gsub("process_name", process_name)
  end

  vim.fn.jobstart(command, {
    -- コマンドの出力をNeovimに表示しないようにする
    stdout_buffered = true,
    stderr_buffered = true,
    -- コマンド終了時に呼ばれる
    on_exit = function(_, exit_code)
      -- exit_codeが0ならプロセスが見つかった、それ以外なら見つからなかった
      local is_running = (exit_code == 0)
      -- 結果をコールバック関数に渡す
      vim.schedule(function()
        callback(is_running)
      end)
    end,
  })
end

-- ビルド実行前のチェック関数
M.is_unreal_engine_busy = function(opts)
  opts = opts or {}
  local target_processes = opts.target_process or {}

  -- 1. 空リストの対応: チェック対象がなければ「実行中でない」としてすぐに終了
  if #target_processes == 0 then
    if opts.on_finish then
      vim.schedule(function()
        opts.on_finish(false)
      end)
    end
    return
  end

  local processes_to_check = #target_processes -- <- 修正点1: 正しいカウンター初期化
  local callback_fired = false -- <- 改善点: コールバックが一度だけ呼ばれるようにするフラグ

  for _, process_name in ipairs(target_processes) do
    local native_process_name = process_name
    if vim.fn.has("win32") == 1 and not native_process_name:find("%.exe$") then
      native_process_name = native_process_name .. ".exe"
    end

    check_process_running_async(native_process_name, function(is_running)
      -- 既に他のプロセスが見つかってコールバックが呼ばれていたら、何もしない
      if callback_fired then
        return
      end

      if is_running then
        -- 2. 早期リターン: プロセスが見つかったら、即座にコールバックを呼んでフラグを立てる
        callback_fired = true
        if opts.on_finish then
          opts.on_finish(true) -- on_finishは非同期コールバックの中から呼ばれるので vim.schedule は不要
        end
        return
      end

      -- プロセスが見つからなかった場合
      processes_to_check = processes_to_check - 1
      -- 全てのプロセスのチェックが完了し、かつ、どれも実行されていなかった場合
      if processes_to_check == 0 and not callback_fired then
        callback_fired = true -- 念のためフラグを立てる
        if opts.on_finish then
          opts.on_finish(false)
        end
      end
    end)
  end
end

-------------------------------------------------
-- Private Helper Functions
-------------------------------------------------

-- ラベル名からプリセット設定を取得する
function M.get_preset_from_label(label)
  for _, v in ipairs(get_config().presets or {}) do
    if v.name == label then
      return v
    end
  end
  return nil
end

local function create_label_target_args(uproject_path, label)

  local preset = M.get_preset_from_label(label)
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
