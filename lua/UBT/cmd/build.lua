-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)

  local cmd = core.create_command_with_target_platforms("Build", opts.label, {"-engine", "-game"})

  if cmd then
    log.notify('build...', vim.log.levels.INFO)
    job.start("Biuld", cmd)
  else
    log.notify("not found project", vim.log.levels.ERROR)
  end
end

return M

