-- lua/UBT/api.lua (シンプルになったAPI)

local unl_finder = require("UNL.finder")
local log = require("UBT.logger")
local cmd = {
  build = require("UBT.cmd.build"),
  gencompiledb = require("UBT.cmd.gen_compile_db"),
  genproject = require("UBT.cmd.gen_proj"),
  lint = require("UBT.cmd.lint"),
  diagnostics = require("UBT.cmd.diagnostics"),
  genheader = require("UBT.cmd.gen_header"),}

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
return M
