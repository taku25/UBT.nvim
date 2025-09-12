-- From: C:\Users\taku3\Documents\git\UBT.nvim\lua\UBT\cmd\build.lua
-- lua/UBT/cmd/build.lua (改修後)

local core = require("UBT.cmd.core")

local ubt_path = require("UBT.path")
local runner = require("UBT.job.runner") -- ジョブランナー
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model") -- プリセット取得用
local log = require("UBT.logger")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)

  opts = core.ensure_command_args(opts, "Build")
  local cmd, err = core.create_command_with_target_platforms(opts, {
    "-WaitMutex",
    "-FromMSBuild", })

  if err then
    return log.get().error(err)
  end

  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")

  -- ★ 変更点: on_finish の中身をシンプルに
  runner.start("Build", cmd, {
    on_finish = function(result_payload) 
      unl_events.publish(unl_types.ON_AFTER_BUILD, result_payload)
    end,
    on_complete = opts.on_complete -- ★ 追加: on_completeをrunnerに渡す
  })
end

function M.start(opts)
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")
    
  unl_events.publish(unl_types.ON_BEFORE_BUILD, {log_file_path = ubt_path.get_progress_log_file_path()})
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
          run_job(opts)
        end
      end,
    })
  else
    run_job(opts)
  end
end

return M
