-- lua/UBT/cmd/build.lua (修正版)

local core = require("UBT.cmd.core")
local ubt_path = require("UBT.path")
local runner = require("UBT.job.runner")
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")
local log = require("UBT.logger")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)
  opts = core.ensure_command_args(opts, "Build")
  local cmd, err = core.create_command_with_target_platforms(opts, {
    "-WaitMutex",
    "-FromMSBuild",
  })

  if err then
    return log.get().error(err)
  end

  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")

  runner.start("Build", cmd, {
    on_finish = function(result_payload)
      unl_events.publish(unl_types.ON_AFTER_BUILD, result_payload)
    end,
    on_complete = opts.on_complete,
  })
end

-- ★★★ ここからが追加された関数です ★★★
---
-- プロセスチェックを行い、安全であればビルドを実行するラッパー関数
-- @param opts table
local function execute_build_if_safe(opts)
  -- 1. 設定からチェック対象のプロセス名リストを取得
  local conf = require("UNL.config").get("UBT")
  local processes_to_check = conf.unreal_processes_name or {}

  -- 2. 非同期でプロセスチェックを実行
  core.is_unreal_engine_busy({
    target_process = processes_to_check,
    on_finish = function(is_busy)
      -- 3. チェック完了後のコールバック
      if is_busy then
        -- 実行中だった場合は警告を出して終了
        local message = "Unreal Engine process is running. Build skipped to prevent conflicts."
        log.get().warn(message)
      else
        -- どのプロセスも実行されていなければ、ビルドジョブを開始
        run_job(opts)
      end
    end,
  })
end
-- ★★★ ここまでが追加された関数です ★★★

function M.start(opts)
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")

  unl_events.publish(unl_types.ON_BEFORE_BUILD, { log_file_path = ubt_path.get_progress_log_file_path() })
  opts = opts or {}
  if opts.has_bang then
    unl_picker.pick({
      kind = "ubt_build",
      title = "  UBT Build Targets",
      conf = require("UNL.config").get("UBT"),
      items = model.get_presets(),
      logger_name = "UBT",
      format = function(entry) return entry.name end,
      preview_enabled = false,
      on_submit = function(selected)
        if selected then
          opts.label = selected.name
          -- ★ 変更点: 直接run_jobを呼ばず、安全チェック関数を呼ぶ
          execute_build_if_safe(opts)
        end
      end,
    })
  else
    -- ★ 変更点: 直接run_jobを呼ばず、安全チェック関数を呼ぶ
    execute_build_if_safe(opts)
  end
end

return M
