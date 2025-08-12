
-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)
  local cmd = core.create_command(opts.root_dir, "GenerateProjectFiles",
  {
    "-game",
    "-engine",
    '-OutputDir',
    opts.root_dir,
  })

  job.start("GenerateProject", cmd)
end

return M

