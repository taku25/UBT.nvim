-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.generate_compile_commands(opts)

  local cmd = core.create_command(opts.label, "Build", {"-NoExecCodeGenActions"})

  log.notify('build...', vim.log.levels.INFO)
  job.start("Biuld", cmd)
end

return M

