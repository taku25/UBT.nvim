-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)
  
  local cmd = core.create_command_with_target_platforms("Build", opts.label,
  {
    "-game",
    "-engine",
  })

  if cmd then
    log.notify('build...', false, vim.log.levels.INFO)
    job.start("Biuld", cmd)
  else
    log.notify("not found project", true, vim.log.levels.ERROR)
  end
end

return M

