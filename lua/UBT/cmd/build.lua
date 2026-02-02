-- lua/UBT/cmd/build.lua
local core = require("UBT.cmd.core")
local ubt_path = require("UBT.path")
local runner = require("UBT.job.runner")
local unl_picker = require("UNL.backend.picker")
local log = require("UBT.logger")
local context = require("UBT.context")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)
  opts = core.ensure_command_args(opts, "Build")
  core.create_command_with_target_platforms(opts, {
    "-WaitMutex",
    "-FromMSBuild",
  }, function(cmd, err)
      if err then
        return log.get().error(err)
      end

      local unl_types = require("UNL.event.types")
      local unl_events = require("UNL.event.events")

      runner.start("Build", cmd, {
        label = opts.label,
        on_finish = function(result_payload)
          unl_events.publish(unl_types.ON_AFTER_BUILD, result_payload)
        end,
        on_complete = opts.on_complete,
      })
  end)
end

---
-- プロセスチェックを行い、安全であればビルドを実行するラッパー関数
-- @param opts table
local function execute_build_if_safe(opts)
  local conf = require("UNL.config").get("UBT")
  local processes_to_check = conf.unreal_processes_name or {}

  core.is_unreal_engine_busy({
    target_process = processes_to_check,
    on_finish = function(is_busy)
      if is_busy then
        local message = "Unreal Engine process is running. Build skipped to prevent conflicts."
        log.get().warn(message)
      else
        run_job(opts)
      end
    end,
  })
end

function M.start(opts)
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")

  unl_events.publish(unl_types.ON_BEFORE_BUILD, { log_file_path = ubt_path.get_progress_log_file_path() })
  opts = opts or {}
  if opts.has_bang then
    -- [!] Circular dependency safety: require model inside function
    local model = require("UBT.model")
    if type(model) ~= "table" then model = package.loaded["UBT.model"] end

    model.get_presets(function(presets)
        unl_picker.pick({
          kind = "ubt_build",
          title = "  UBT Build Targets",
          conf = require("UNL.config").get("UBT"),
          items = presets,
          logger_name = "UBT",
          format = function(entry) return entry.name end,
          preview_enabled = false,
          on_submit = function(selected)
            if selected then
              opts.label = selected.name
              context.set("last_preset", selected.name)
              execute_build_if_safe(opts)
            end
          end,
        })
    end)
  else
    execute_build_if_safe(opts)
  end
end

return M