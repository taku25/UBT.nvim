--- Writer backend for showing user-facing notifications.
-- This module implements the "Writer" interface and is responsible
-- for displaying important messages (errors, warnings, final status)
-- to the user via vim.notify.

M = {}

M.level_to_string = function (level)
    local level_names = {
      [vim.log.levels.ERROR] = "ERROR",
      [vim.log.levels.WARN]  = "WARN",
      [vim.log.levels.INFO]  = "INFO",
    }
    return level_names[level] or "UNKNOWN"
end

M.should_display = function (level, config_level)
    local levels = {
      ERROR = { "ERROR", "WARN", "ALL" },
      WARN  = { "WARN", "ALL" },
      INFO  = { "ALL" },
    }

    local name = M.level_to_string(level)
    return name and vim.tbl_contains(levels[name], config_level)
end


M.level_to_highlight = function(level)
  return (level == vim.log.levels.ERROR and "ErrorMsg")
          or (level == vim.log.levels.WARN and "WarningMsg")
          or "Normal"
end
return M;
