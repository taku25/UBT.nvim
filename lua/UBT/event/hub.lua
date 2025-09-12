local unl_events = require("UNL.event.events")
local unl_event_types = require("UNL.event.types")

local M = {}

M.setup = function()
  -- ★ 変更点: 設定を最初に一度だけ読み込む
  local conf = require("UNL.config").get("UBT")

  local function gen_header()
    require("UBT.cmd.gen_header").start({
      on_complete = function(_payload)
        -- ★ 変更点: 2つ目の自動化設定をチェックし、ペイロードの.successを見る
        if conf.automation.auto_gen_project_after_gen_header_success then
          if _payload.success then
            require("UBT.cmd.gen_proj").start()
          end
        end
      end,
    })
  end

  local function gen_project()
    require("UBT.cmd.gen_proj").start()
  end

  -- ★ 変更点: 1つ目の自動化設定をチェックしてからイベントを購読する
  if conf.automation.auto_gen_header_after_lightweight_refresh then
    unl_events.subscribe(unl_event_types.ON_AFTER_UEP_LIGHTWEIGHT_REFRESH, function()
      gen_header()
    end)
  end

  -- ★ 変更点: 3つ目の自動化設定をチェックしてからイベントを購読する
  if conf.automation.auto_gen_project_after_refresh_completed then
    unl_events.subscribe(unl_event_types.ON_AFTER_REFRESH_COMPLETED, function()
      gen_project()
    end)
  end
end

return M
