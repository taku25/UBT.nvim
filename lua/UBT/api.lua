-- lua/UBT/api.lua (修正版)
local M = {}

function M.build(opts)
  require("UBT.cmd.build").start(opts)
end

function M.gen_compile_db(opts)
  require("UBT.cmd.gen_compile_db").start(opts)
end

function M.gen_project(opts)
  require("UBT.cmd.gen_proj").start(opts)
end

function M.lint(opts)
  require("UBT.cmd.lint").start(opts)
end

function M.diagnostics(opts)
  require("UBT.cmd.diagnostics").start(opts)
end

function M.gen_header(opts)
  require("UBT.cmd.gen_header").start(opts)
end

function M.run(opts)
  require("UBT.cmd.run").start(opts)
end

return M
