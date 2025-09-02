-- lua/UBT/cmd/gen_compile_db.lua (UI判断ロジックを含む最終版)

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner") -- ジョブランナー
local unl_picker = require("UNL.backend.picker")
local log = require("UBT.logger")
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)

  opts = core.ensure_command_args(opts, "GenerateClangDatabase")

  local cmd, err = core.create_command_with_target_platforms(opts, {
    "-NoExecCodeGenActions",
    "-OutputDir=" ..'"'.. opts.root_dir ..'"',
  })

  if err then
    return log.get().error(err)
  end

  -- 変更点: on_finish で結果テーブルを受け取り、ペイロードを作成する
  runner.start("GenerateClangDatabase", cmd, {
    on_finish = function(result_table) -- 引数としてテーブルを受け取る
      -- result_table.success の値に基づいてステータスを決定
      local result_payload = {
        status = result_table.success and "success" or "failed"
      }
      -- 決定したペイロードを付けてイベントを発行
      unl_events.publish(unl_types.ON_AFTER_GENERATE_COMPILE_DATABASE, result_payload)
    end
  })
end

function M.start(opts)
  opts = opts or {}
  if opts.has_bang then
    -- `!`付きの場合は、UIピッカーを起動
    unl_picker.pick({
      kind = "  ubt_gencompiledb",
      title = "UBT Generate Compile DB Targets",
      logger_name = "UBT",
      preview_enabled = false,
      conf = require("UNL.config").get("UBT"),
      items = picker_model.get_presets(),
      format = function(entry) return entry.name end,
      on_submit = function(selected)
        if selected then
          opts.label = selected.name
          run_job(opts)
        end
      end,
    })
  else
    -- `!`がなければ、そのままジョブを実行
    run_job(opts)
  end
end

return M
