--- Writer backend for showing user-facing notifications.
-- This module implements the "Writer" interface and is responsible
-- for displaying important messages (errors, warnings, final status)
-- to the user via vim.notify.
local M = {}

local conf = require("UBT.conf")
-- "Writer" interface implementation
-------------------------------------

-- ジョブ開始時には、何もしない（静かに見守る）

-- ジョブ終了時に、最終結果を通知する
function M.on_job_exit(code)
  local level = (code == 0) and vim.log.levels.INFO or vim.log.levels.ERROR
  local status_message = (code == 0) and "Succeeded" or "Failed"
  local message = string.format("Job finished: %s (code %d)", status_message, code)

  if conf.enable_notify == true then
    -- fidgetが使えればそちらを優先、なければvim.notifyを使う
    local fidget_ok, fidget = pcall(require, 'fidget')
    if fidget_ok then
      fidget.notify(message, level, { title = "UBT Status" })
    else
      vim.notify(message, level, { title = "UBT Status" })
    end
  end

  if conf.enable_message == true then
    if level == vim.log.levels.ERROR then
      vim.api.nvim_echo({{message, "ErrorMsg" }}, true, {err=true})
    elseif level == vim.log.levels.WARNING then
      vim.api.nvim_echo({{message, "WarningMsg" }}, true, {err=true})
    end
  end
  
end

function M.on_progress_update(label, percentage)
  local fidget_ok, fidget = pcall(require, 'fidget')
  if fidget_ok then
    fidget.notify(message, level, { title = "UBT" })
  else
    if conf.enable_notify == true then
      vim.notify(message, level, { title = "UBT" })
    end
    if conf.enable_message == true then
      if level == vim.log.levels.ERROR then
        vim.api.nvim_echo({{message, "ErrorMsg" }}, true, {err=true})
      elseif level == vim.log.levels.WARNING then
        vim.api.nvim_echo({{message, "WarningMsg" }}, true, {err=true})
      end
    end
  end
end

-- 通常のログメッセージ書き込み時に呼ばれる



function M.write(message, level)
  local notify = function(message, level)
    local fidget_ok, fidget = pcall(require, 'fidget')
    if fidget_ok then
      fidget.notify(message, level, { title = "UBT" })
    else
      vim.notify(message, level, { title = "UBT" })
    end
  end
       

  local should_display = function (level, config_level)
    local levels = {
      ERROR = { "ERROR", "WARN", "ALL" },
      WARN  = { "WARN", "ALL" },
      INFO  = { "ALL" },
    }

    local level_names = {
      [vim.log.levels.ERROR] = "ERROR",
      [vim.log.levels.WARN]  = "WARN",
      [vim.log.levels.INFO]  = "INFO",
    }

    local name = level_names[level]
    return name and vim.tbl_contains(levels[name], config_level)
  end


  if conf.notify_level ~= "NONE" and should_display(level, conf.notify_level) then
    notify(message, level)
  end

  if conf.message_level ~= "NONE" and should_display(level, conf.message_level) then
    local hl = (level == vim.log.levels.ERROR and "ErrorMsg")
            or (level == vim.log.levels.WARN and "WarningMsg")
            or "Normal"
    vim.api.nvim_echo({{message, hl}}, level ~= vim.log.levels.INFO, {err = level ~= vim.log.levels.INFO})
  end
end

return M
