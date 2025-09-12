local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local log = require("UBT.logger")
local unl_types = require("UNL.event.types")
local unl_events = require("UNL.event.events")

local M = {}

function M.start(opts)
  opts = core.ensure_command_args(opts, "GenerateProjectFiles")
  local cmd, err = core.create_command(opts.root_dir, opts.mode, {
    "-game",
    "-engine",
    "-OutputDir=" .. '"'..opts.root_dir..'"',
  })


  if err then
    return log.get().error(err)
  end

  -- 変更点: on_finish で結果テーブルを受け取り、ペイロードを作成
  runner.start("GenerateProject", cmd, {
    on_finish = function(result_payload) -- ★ 変更
      unl_events.publish(unl_types.ON_AFTER_GENERATE_PROEJCT, result_payload)
    end,
    on_complete = opts.on_complete -- ★ 追加
  })
end

return M
