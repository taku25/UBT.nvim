local fzf_lua = require("fzf-lua")
local model = require("UBT.model")
local api = require("UBT.api")

local M={}

M.exec = function()
  fzf_lua.fzf_exec(
    function(fzf_cb)
      local presets = model.get_presets()
      if not presets or #presets == 0 then
        fzf_cb()
        return
      end
      coroutine.wrap(function()
        local co = coroutine.running()
        for _, preset in ipairs(presets) do
          fzf_cb(preset.name, function() coroutine.resume(co) end)
          coroutine.yield()
        end
        fzf_cb()
      end)()
    end,
    {
      prompt = "  ubt build >",
      actions = {
        ["default"] = function(selected)
         api.build({ label = selected[1] })
       end,
      }
    }
  )
end

return M
