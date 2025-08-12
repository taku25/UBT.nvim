-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)

  local cmd, error= core.create_command_with_target_platforms(opts.root_dir, "GenerateClangDatabase", opts.label, 
  {
    "-NoExecCodeGenActions",
    '-OutputDir',
    opts.root_dir,
  })
  if error ~= nil then
    return nil, error
  end
  
  return job.start("GenerateClangDatabase", cmd), nil
end

return M

