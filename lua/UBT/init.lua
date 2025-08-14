--- UBT.nvim: Main plugin entry point for setup.
-- This file is responsible for initializing the plugin.
-- To access the Lua API, please `require("UBT.api")`.
local M = {}

local conf = require("UBT.conf")
local logger = require("UBT.logger")

--- The main setup function for the plugin.
-- Must be called to initialize the plugin.
-- @param user_conf table|nil: The user's configuration table.
function M.setup(user_conf)
  local err = conf.setup(user_conf)
  if err then
    -- Logger might not be fully set up, so use vim.notify directly as a fallback.
    vim.notify("UBT.nvim Configuration Error: " .. err, vim.log.levels.ERROR)
  end

  logger.on_plugin_setup(conf.active_config)
  
  local telescope_ok, telescope = pcall(require, "telescope")
  if telescope_ok then
    telescope.load_extension("ubt")
  end
end

return M
