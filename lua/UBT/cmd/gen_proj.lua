
-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")
local util = require("UBT.util")

--- compile_commands.json生成本体
function M.start()
  local project_root = util.get_uprojct_root_path()

  local cmd = core.create_command("GenerateProjectFiles",
  {
    "-game",
    "-engine",
    '-OutputDir',
    project_root,
  })

  if cmd then
    log.notify('Generating Project...', true, vim.log.levels.INFO)
    job.start("GenerateProject", cmd)
  else
    log.notify("not found project", false, vim.log.levels.ERROR)
  end
end

return M

