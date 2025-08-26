-- lua/UBT/cmd/gen_compile_db.lua (UI判断ロジックを含む最終版)

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner") -- ジョブランナー
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model") -- プリセット取得用
local log = require("UBT.logger")
local unl_finder = require("UNL.finder")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)

  local cmd, err = core.create_command_with_target_platforms(opts.root_dir, "GenerateClangDatabase", opts.label, {
    "-NoExecCodeGenActions",
    "-OutputDir=" .. opts.root_dir,
  })

  if err then
    return log.get().error(err)
  end
  runner.start("GenerateClangDatabase", cmd)
end

function M.start(opts)
  if opts.has_bang then
    -- `!`付きの場合は、UIピッカーを起動
    unl_picker.pick({
      kind = "ubt_gencompiledb",
      title = "UBT Generate Compile DB Targets",
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
