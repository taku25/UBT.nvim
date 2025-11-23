local unl_log = require("UNL.logging")
local ubt_defaults = require("UBT.config.defaults")

local progress_log_writer = require("UBT.writer.progress_log")

local M = {}

function M.setup(user_opts)
  unl_log.setup("UBT", ubt_defaults, user_opts or {})

  -- 2. 次に、UBT専用のカスタムwriterを後から「登録」する
  unl_log.add_writer("UBT", progress_log_writer.new())

  local log = unl_log.get("UBT")

  require("UBT.event.hub").setup()
  require("UBT.provider").setup()
  if log then
    log.debug("UBT.nvim setup complete.")
  else
  end
end


return M
