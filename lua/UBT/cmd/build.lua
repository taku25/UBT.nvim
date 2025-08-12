-- UBT.nvim: Neovim command registration module
-- gen_compile_db.lua
local M = {}
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)
  
  local cmd = core.create_command_with_target_platforms(opts.root_dir, "Build", opts.label,
  {
    "-game",
    "-engine",
  })

  job.start("Biuld", cmd)
end

return M

