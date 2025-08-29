local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local log = require("UBT.logger")
local unl_types = require("UNL.event.types")
local unl_events = require("UNL.event.events")

local M = {}

function M.start(opts)
  local cmd, err = core.create_command(opts.root_dir, "GenerateProjectFiles", {
    "-game",
    "-engine",
    "-OutputDir=" .. '"'..opts.root_dir..'"',
  })

  if err then
    return log.get().error(err)
  end

  -- 変更点: on_finish で結果テーブルを受け取り、ペイロードを作成
  runner.start("GenerateProject", cmd, {
    on_finish = function(result_table) -- 引数としてテーブルを受け取る
      local result_payload = {
        status = result_table.success and "success" or "failed"
      }
      -- 成功/失敗ステータスを含むペイロードをイベントに渡す
      unl_events.publish(unl_types.ON_AFTER_GENERATE_PROEJCT, result_payload)
    end
  })
end

return M
