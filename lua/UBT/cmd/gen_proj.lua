
-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")
local util = require("UBT.util")

--- compile_commands.json生成本体
function M.start(opts)
  local cmd = core.create_command(opts.root_dir, "GenerateProjectFiles",
  {
    "-game",
    "-engine",
    '-OutputDir',
    opts.root_dir,
  })

  if cmd then
    log.notify('Generating Project...', true, vim.log.levels.INFO)
    job.start("GenerateProject", cmd)
  else
    log.notify("not found project", false, vim.log.levels.ERROR)
  end
end

return M

