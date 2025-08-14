--- UBT.nvim: Core command execution logic.
-- This module is for internal use only and is not considered part of the public API.
-- It handles command definitions, argument parsing, and dispatching to handlers.
local M = {}

local conf = require("UBT.conf")
local cmd = require("UBT.cmd") -- This loads cmd/init.lua
local logger = require("UBT.logger")

-- The single source of truth for all command definitions.
local subcommands = {
  build = {
    handler = cmd.build,
    desc = "Build the project.",
    args = {
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },
  gencompiledb = {
    handler = cmd.gen_compile_db,
    desc = "Generate compile database.",
    args = {
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },
  genproject = {
    handler = cmd.gen_proj,
    desc = "Generate project files.",
    args = {},
  },
  lint = {
    handler = cmd.lint,
    desc = "Run static analyzer.",
    args = {
      { name = "lintType", default = function() return conf.active_config.lint_type end },
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },
}

--- The single, internal function for executing any command.
-- @param sub_name string: The name of the subcommand to execute (e.g., "build").
-- @param user_opts table|nil: Options provided by the user, e.g., { label = "Win64Debug" }.
function M.execute_command(sub_name, user_opts)
  user_opts = user_opts or {}
  
  -- Ensure the configuration is up-to-date for the current project.
  conf.load_config(user_opts.root_dir or vim.fn.getcwd())

  -- Look up the command definition.
  local command_def = subcommands[sub_name:lower()]
  if not command_def then
    logger.write("Unknown subcommand: " .. sub_name, vim.log.levels.ERROR)
    return
  end

  -- Prepare the final options table for the command handler.
  local opts = {
    root_dir = user_opts.root_dir or vim.fn.getcwd(),
  }

  -- Parse arguments, applying defaults if user values are not provided.
  for i, arg_def in ipairs(command_def.args) do
    local value = user_opts[arg_def.name] or arg_def.default()
    opts[arg_def.name] = value
  end
  
  logger.write(string.format("Executing command: '%s' with options: %s", sub_name, vim.inspect(opts)), vim.log.levels.INFO)
  
  -- Dispatch to the actual command handler.
  command_def.handler.start(opts)
end

return M
