-- lua/UBT/cmd/gen_compile_db.lua (最新版・フラグ修正済み)

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")
local log = require("UBT.logger")
local unl_types = require("UNL.event.types")
local unl_events = require("UNL.event.events")

local M = {}

local function run_job(opts)
  opts = core.ensure_command_args(opts, "GenerateClangDatabase")

  -- ▼▼▼ ここで -NoExecCodeGenActions を追加します ▼▼▼
  local extra = {
    "-NoExecCodeGenActions",
  }
  if vim.fn.has("win32") == 1 then
    table.insert(extra, "-OutputDir=" .. '"' .. opts.root_dir .. '"')
  else
    table.insert(extra, "-OutputDir=" .. opts.root_dir)
  end
  -- ▲▲▲ ここまで ▲▲▲

  local cmd, err = core.create_command_with_target_platforms(opts, extra)

  if err then
    return log.get().error(err)
  end

  runner.start("GenerateClangDatabase", cmd, {
    on_finish = function(result_payload)
      unl_events.publish(unl_types.ON_AFTER_GENERATE_COMPILE_DATABASE, result_payload)
    end,
    on_complete = opts.on_complete,
  })
end

function M.start(opts)
  opts = opts or {}
  if opts.has_bang then
    unl_picker.pick({
      kind = "ubt_gencompiledb",
      title = "UBT Generate Compile DB Targets",
      logger_name = "UBT",
      preview_enabled = false,
      conf = require("UNL.config").get("UBT"),
      items = model.get_presets(),
      format = function(entry) return entry.name end,
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
