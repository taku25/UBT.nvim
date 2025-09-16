-- lua/UBT/api.lua (修正版)
local cmd = {
  build = require("UBT.cmd.build"),
  gencompiledb = require("UBT.cmd.gen_compile_db"),
  genproject = require("UBT.cmd.gen_proj"),
  lint = require("UBT.cmd.lint"),
  diagnostics = require("UBT.cmd.diagnostics"),
  genheader = require("UBT.cmd.gen_header"),
  run = require("UBT.cmd.run"), -- ★ この行を追加
}

local M = {}

function M.build(opts)
  cmd.build.start(opts)
end

function M.gen_compile_db(opts)
  cmd.gencompiledb.start(opts)
end

function M.gen_project(opts)
  cmd.genproject.start(opts)
end

function M.lint(opts)
  cmd.lint.start(opts)
end

function M.diagnostics(opts)
  cmd.diagnostics.start(opts)
end

function M.gen_header(opts)
  cmd.genheader.start(opts)
end

-- ★ この関数を追加
function M.run(opts)
  cmd.run.start(opts)
end

return M
