-- lua/UBT/cmd/gen_header.lua
-- Unreal Header Tool (-Mode=GenerateHeader) を実行するコマンド

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local unl_picker = require("UNL.picker")
local model = require("UBT.model")
local log = require("UBT.logger")
local unl_finder = require("UNL.finder")
local context = require("UBT.context")

local M = {}

-- ジョブを実際に実行するコア部分
local function run_job(opts)
  local unl_types = require("UNL.event.types")
  local unl_events = require("UNL.event.events")
  -- 必須引数を準備し、モードを "GenerateHeader" に設定
  opts = core.ensure_command_args(opts, "GenerateHeader")

  --何かあれば引数追加
  local extra = {}

  local project_info = unl_finder.project.find_project(opts.root_dir)
  
  local function proceed_with_command(extra_args)
      -- UBT実行コマンドを生成
      core.create_command_with_target_platforms(opts, extra_args, function(cmd, err)
          if err then
            return log.get().error(err)
          end

          -- ジョブを開始
          runner.start("GenerateHeader", cmd, {
            label = opts.label,
            on_finish = function(result_payload)
              unl_events.publish(unl_types.ON_AFTER_GENERATE_HEADER, result_payload)
            end,
            on_complete = opts.on_complete
          })
      end)
  end

  if project_info then
    core.get_preset_from_label(opts.label, function(preset)
        if preset then
          local manifest_path, find_err = unl_finder.build_artifact.find_uht_manifest({
            project_root = project_info.root,
            project_name = vim.fn.fnamemodify(project_info.uproject, ":t:r"),
            target_preset = preset,
          })

          if manifest_path then
            table.insert(extra, "-Manifest=" .. '"' .. manifest_path .. '"')
            log.get().info("Using UHT manifest for incremental build: %s", manifest_path)
          elseif find_err then
            log.get().debug("Could not find UHT manifest: %s", find_err)
          end
        end
        proceed_with_command(extra)
    end)
  else
    proceed_with_command(extra)
  end
end

-- コマンドのエントリーポイント
function M.start(opts)
  opts = opts or {}
  if opts.has_bang then
    -- `!`付きの場合は、UIピッカーを起動
    model.get_presets(function(presets)
        unl_picker.open({
          kind = "ubt_genheader",
          title = " UBT Generate Header Targets",
          conf = require("UNL.config").get("UBT"),
          items = presets,
          logger_name = "UBT",
          entry_maker = function(item)
            return {
              value = item,
              display = item.name,
            }
          end,
          preview_enabled = false,
          on_submit = function(selected)
            if selected then
              opts.label = selected.name
              context.set("last_preset", selected.name)
              run_job(opts)
            end
          end,
        })
    end)
  else
    -- `!`がなければ、そのままジョブを実行
    run_job(opts)
  end
end

return M

