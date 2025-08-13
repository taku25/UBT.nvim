-- UBT.nvim: Unreal Engine compile_commands.json generator for Neovim
-- setup only

local M = {}
local conf = require("UBT.conf")
local logger = require("UBT.logger")

function M.setup(user_conf)
  conf.setup(user_conf)
  logger.on_plugin_setup(user_conf)

  local fidget_available = pcall(require, 'fidget')
  if fidget_available then
    if conf.active_config.enable_override_fidget == true then
      local fidget = require("fidget")
      -- 安定してモジュールが初期化された後に呼ぶ
      local display = require("fidget.progress.display")
      local ubtOpts = {
        format_group_name = function(group)
          return "UBT:" .. tostring(group)
        end,
        overrides = {
          UBT = {
            name = "Unreal Build Tool",
            icon = fidget.progress.display.for_icon(fidget.spinner.animate("dots", 2.5), "✔️"),
            update_hook = function(item)
              require("fidget.notification").set_content_key(item)
              if item.hidden == nil and string.match(item.annote, "clippy") then
                item.hidden = true
              end
            end,
          }
        },
      }
      require("fidget.options").declare(display, "progress.display", ubtOpts)
    end
  end
  --
end

return M

