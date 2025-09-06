-- lua/UBT/cmd/build.lua (UI判断ロジックを含む最終版)

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

  -- 変更後: on_finish がテーブルを引数として受け取る
  runner.start("Build", cmd, {
    -- 引数を result_table のような名前にして、中身を展開する
    on_finish = function(result_table) 
      -- result_table.success の値に基づいてステータス文字列を決定
      local result_payload = {
        status = result_table.success and "success" or "failed"
      }
      -- 決定したステータスをペイロードとしてイベントを発行
      unl_events.publish(unl_types.ON_AFTER_BUILD, result_payload)
    end
  })
end

function M.start(opts)
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")
    
  unl_events.publish(unl_types.ON_BEFORE_BUILD, {log_file_path = ubt_path.get_progress_log_file_path()})
  opts = opts or {}
  if opts.has_bang then
    -- `!`付きの場合は、UIピッカーを起動
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
          -- ピッカーで選択されたものでジョブを実行
          opts.label = selected.name
          run_job(opts)
        end
      end,
    })
  else
    -- `!`がなければ、そのままジョブを実行
    -- (opts.labelには、ユーザーが入力した値か、builderが設定したデフォルト値が入っている)
    run_job(opts)
  end
end

return M
