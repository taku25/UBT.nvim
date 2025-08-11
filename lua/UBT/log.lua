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


function M.notify(message, notifyType, title)
  notifyType = notifyType or vim.log.levels.INFO
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


  if notifyType == vim.log.levels.ERROR then
    vim.api.nvim_echo({{formatted, "ErrorMsg" }}, true, {err=true})
  elseif notifyType == vim.log.levels.WARNING then
    vim.api.nvim_echo({{formatted, "WarningMsg" }}, true, {err=true})
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
