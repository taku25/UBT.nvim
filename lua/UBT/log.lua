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

  -- テーブルなら整形
  local formatted = type(message) == "table" and vim.inspect(message) or tostring(message)

  if notifyType == vim.log.levels.ERROR then


    vim.api.nvim_echo({{formatted, "ErrorMsg" }}, true, {err=true})
    -- vim.api.nvim_echo({formatted,"ErrorMsg"}, true)
  elseif notifyType == vim.log.levels.WARNING then
    local escaped = formatted:gsub('"', '\\"')
    vim.cmd('echohl WarningMsg | echomsg "' .. escaped .. '" | echohl None')
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
