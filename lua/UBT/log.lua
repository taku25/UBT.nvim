-- UBT.nvim: Neovim command registration module
-- log.lua
local M = {}

local function is_empty_string_table(tbl)
  if type(tbl) ~= "table" then return false end
  for _, v in ipairs(tbl) do
    if v ~= "" then return false end
  end
  return true
end


function M.notify(message, write_message_win, notify_type, title)
  notify_type = notify_type or vim.log.levels.INFO
  title = title or "UBT"

  if is_empty_string_table(message) then
    return nil
  end

  -- テーブルなら整 == "table" and vim.inspect(message):gsub("\r\n", "\n"):gsub("\r", "\n") or tostring(message)
  local formatted ="" 

  if type(message) == "table" then
    formatted = table.concat(message, "\n")
  else
    formatted = tostring(message)
  end

  if write_message_win == true then
    if notify_type == vim.log.levels.ERROR then
      vim.api.nvim_echo({{formatted, "ErrorMsg" }}, true, {err=true})
    elseif notify_type == vim.log.levels.WARNING then
      vim.api.nvim_echo({{formatted, "WarningMsg" }}, true, {err=true})
    else
      vim.api.nvim_echo({{formatted, "Normal" }}, true, {err=false})
    end
  end

  local conf = require("UBT.conf")
  if conf.notify ~= false then
    local fidget_available = pcall(require, 'fidget')
    if fidget_available then
      return require('fidget').notify(formatted, notifyType,{ title = title })
    else
      return vim.notify(formatted, notifyType, { title = title })
    end
  end

  return nil
end

return M
