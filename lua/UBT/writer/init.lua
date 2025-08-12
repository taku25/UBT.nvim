-- lua/UBT/cmd/init.lua

-- このテーブルが、`require("UBT.cmd")` の返り値になる
--- UBT.nvim's writer backend modules.
-- This module acts as a facade, collecting all available writers
-- into a single list for the main logger to consume.

local writers = {
  require("UBT.writer.log"),
  require("UBT.writer.notify"),
  require("UBT.writer.progress"),
}

return writers
