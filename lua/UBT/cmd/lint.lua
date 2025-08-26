-- lua/UBT/cmd/lint.lua

local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local log = require("UBT.logger")
local unl_finder = require("UNL.finder")

local M = {}

function M.start(opts)
  local cmd, err = core.create_command_with_target_platforms(opts.root_dir, nil, opts.label, {
    "-game",
    "-engine",
    "-StaticAnalyzer=" .. opts.lintType,
  })

  if err then
    return log.get().error(err)
  end

  runner.start("StaticAnalyzer", cmd)
end

return M
