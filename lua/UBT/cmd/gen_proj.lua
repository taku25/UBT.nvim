local core = require("UBT.cmd.core")
local runner = require("UBT.job.runner")
local log = require("UBT.logger")
local unl_finder = require("UNL.finder")

local M = {}

function M.start(opts)

  local cmd, err = core.create_command(opts.root_dir, "GenerateProjectFiles", {
    "-game",
    "-engine",
    "-OutputDir=" .. opts.root_dir,
  })

  if err then
    return log.get().error(err)
  end
  
  runner.start("GenerateProject", cmd)
end

return M
