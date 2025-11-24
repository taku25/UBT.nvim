-- lua/UBT/provider/init.lua
local log = require("UBT.logger").get()

local M = {}

M.setup = function()
  local unl_api_ok, unl_api = pcall(require, "UNL.api")
  if unl_api_ok then
    
    -- 1. Launch Config Provider の登録 (既存)
    local launch_provider = require("UBT.provider.launch")
    unl_api.provider.register({
      capability = "ubt.get_launch_config",
      name = "UBT.nvim",
      impl = launch_provider,
    })

    -- 2. Presets Provider の登録 (★ 新規追加)
    local presets_provider = require("UBT.provider.presets")
    unl_api.provider.register({
      capability = "ubt.get_presets",
      name = "UBT.nvim",
      impl = presets_provider,
    })

    if log then
      log.debug("Registered UEP providers to UNL.nvim.")
    end
  end
end

return M
