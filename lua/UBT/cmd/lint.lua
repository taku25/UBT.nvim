-- UBT.nvim: Neovim command registration module
-- lint.lua
local M = {}
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)
  
  local cmd,error = core.create_command_with_target_platforms(opts.root_dir, nil, opts.label,
  {
    "-game",
    "-engine",
    "-StaticAnalyzer",
    opts.lint_type
  })

  if error ~= nil then
    return nil, error
  end
  --
  return job.start("StaticAnalyzer", cmd), nil
end

return M

