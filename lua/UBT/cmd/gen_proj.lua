
-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start()

  local cmd = core.create_command("GenerateProjectFiles", {"-game -engine"})

  log.notify('Generating Project...', vim.log.levels.INFO)
  job.start("GenerateProject", cmd)
end

return M

