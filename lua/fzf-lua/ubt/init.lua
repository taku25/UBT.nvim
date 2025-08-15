
-- lua/fzf-lua/ubt/init.lua

-- このテーブルが、`require("UBT.cmd")` の返り値になる
--- UBT.nvim's writer backend modules.
-- This module acts as a facade, collecting all available writers
-- into a single list for the main logger to consume.

local M = {}


M.build = require("fzf-lua.ubt.build")
M.gen_compile_db = require("fzf-lua.ubt.gen_compile_db")
M.diagnostics = require("fzf-lua.ubt.diagnostics")

return M
