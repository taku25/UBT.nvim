-- lua/UBT/cmd/lint.lua

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local log = require("UBT.logger")
  
local unl_types = require("UNL.event.types")
local unl_events = require("UNL.event.events")

local M = {}

function M.start(opts)
  -- この require はファイルの先頭に移動させるのが一般的です (機能はしますが)
  -- local unl_types = require("UNL.event.types") 
  opts = core.ensure_command_args(opts,"")

  local cmd, err = core.create_command_with_target_platforms(opts,  {
    "-game",
    "-engine",
    "-StaticAnalyzer=" .. opts.lintType,
  })

  if err then
    return log.get().error(err)
  end

  -- 変更点: on_finish で結果テーブルを受け取り、ペイロードを作成
  runner.start("StaticAnalyzer", cmd, {
    on_finish = function(result_payload) -- ★ 変更
      unl_events.publish(unl_types.ON_AFTER_LINT, result_payload)
    end,
    on_complete = opts.on_complete -- ★ 追加
  })
end

return M
