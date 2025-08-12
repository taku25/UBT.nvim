-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")
local util = require("UBT.util")

--- compile_commands.json生成本体
function M.start(opts)

  local cmd = core.create_command_with_target_platforms("GenerateClangDatabase", opts.label, 
  {
    "-NoExecCodeGenActions",
    '-OutputDir',
    util.get_uprojct_root_path(),
  })
  
  if cmd then
    log.notify('Generating compile_commands.json...', false, vim.log.levels.INFO)
    job.start("GenerateClangDatabase", cmd)
  else
    log.notify("not found project", true, vim.log.levels.ERROR)
  end

end

return M

