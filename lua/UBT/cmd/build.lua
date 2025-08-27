-- lua/UBT/cmd/build.lua (UI判断ロジックを含む最終版)

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner") -- ジョブランナー
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model") -- プリセット取得用
local log = require("UBT.logger")
local unl_finder = require("UNL.finder")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)
  local cmd, err = core.create_command_with_target_platforms(opts.root_dir, "Build", opts.label, {
    "-WaitMutex",
    "-FromMSBuild", --これどうにかしたい
  })
  if err then
    return log.get().error(err)
  end
  runner.start("Build", cmd)
end

function M.start(opts)
  if opts.has_bang then
    -- `!`付きの場合は、UIピッカーを起動
    unl_picker.pick({
      kind = "ubt_build",
      title = "  UBT Build Targets",
      conf = require("UNL.config").get("UBT"),
      items = model.get_presets(),
      logger_name = "UBT",
      format = function(entry) return entry.name end,
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
