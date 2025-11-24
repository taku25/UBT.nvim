-- lua/UBT/provider/presets.lua
local model = require("UBT.model")
local log = require("UBT.logger").get()

local M = {}

---
-- UBTが認識している全てのプリセット（静的 + 動的）を返す
-- @param opts table (未使用)
-- @return table リスト
function M.request(opts)
  log.debug("Provider 'ubt.get_presets' called.")
  
  -- UBTのモデルが持つ、UEPとのマージ済みリストを取得してそのまま返す
  local presets = model.get_presets()
  
  return presets
end

return M
