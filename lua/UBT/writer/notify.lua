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
  -- ERRORとWARNレベルのメッセージだけをフィルタリングして通知する
   if level == vim.log.levels.ERROR or level == vim.log.levels.WARN then
    local fidget_ok, fidget = pcall(require, 'fidget')
    if fidget_ok then
      fidget.notify(message, level, { title = "UBT" })
    else
      if conf.enable_notify == true then
        vim.notify(message, level, { title = "UBT" })
      end
    end
  end
    
  if level == vim.log.levels.ERROR then
    vim.api.nvim_echo({{message, "ErrorMsg" }}, true, {err=true})
  elseif level == vim.log.levels.WARNING then
    vim.api.nvim_echo({{message, "WarningMsg" }}, true, {err=true})
  else
    if conf.enable_message == true then
      vim.api.nvim_echo({{message, "Normal" }}, false, {err=false})
    end
  end
end

return M
