-- UBT.nvim: Neovim command registration module
-- lint.lua
local M = {}
local log = require("UBT.log")
local job = require("UBT.job.runner")
local core = require("UBT.cmd.core")

--- compile_commands.json生成本体
function M.start(opts)
  
  local cmd = core.create_command_with_target_platforms(opts.root_dir, nil, opts.label,
  {
    "-game",
    "-engine",
    "-StaticAnalyzer",
    opts.lint_type
  })
  --
  if cmd then
    log.notify('lint...', false, vim.log.levels.INFO)
    job.start("StaticAnalyzer", cmd)
  else
    log.notify("not found project", true, vim.log.levels.ERROR)
  end
end

return M

