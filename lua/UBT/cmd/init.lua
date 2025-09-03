-- lua/UBT/cmd/init.lua

-- このテーブルが、`require("UBT.cmd")` の返り値になる
local M = {}

M.gen_compile_db = require("UBT.cmd.gen_compile_db")
M.build = require("UBT.cmd.build")
M.gen_proj = require("UBT.cmd.gen_proj")
M.lint = require("UBT.cmd.lint")
M.gen_header = require("UBT.cmd.gen_header")

return M
