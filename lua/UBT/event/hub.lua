local unl_events = require("UNL.event.events")
local unl_event_types = require("UNL.event.types")


local M = {}


M.setup = function()

  local function gen_header(payload)
    require("UBT.cmd.gen_header").start()
  end

  unl_events.subscribe(unl_event_types.ON_AFTER_UEP_LIGHTWEIGHT_REFRESH, function(playload) gen_header(playload) end)
end


return M
