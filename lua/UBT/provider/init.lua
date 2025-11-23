-- lua/UBT/provider/init.lua
local log = require("UBT.logger").get()

local M = {}

M.setup = function()
  local unl_api_ok, unl_api = pcall(require, "UNL.api")
  if unl_api_ok then
    
    -- Launch Config Provider の登録
    local launch_provider = require("UBT.provider.launch")
    unl_api.provider.register({
      capability = "ubt.get_launch_config",
      name = "UBT.nvim",
      impl = launch_provider,
    })

    if log then
      log.debug("Registered UEP providers to UNL.nvim.")
    end
  end
end

return M
