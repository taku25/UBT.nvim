-- UBT.nvim: Neovim command registration module
-- job.runner.lua

local M = {}
local uv = vim.loop

local log = require("UBT.log")

local progress = nil
local message_buffer = ""

local function flush_message(msg)
  msg = msg:match("^%s*(.-)%s*$") -- trim

  if msg == "" then return end

  -- progress
  local label, percent = msg:match("@progress%s+'([^']+)'%s+(%d+)%%")
  if label and percent then
    if progress then
      progress:report({
        message = label,
        percentage = tonumber(percent),
      })
    end
    return
  end

  -- error
  -- if msg:match("[Ee]rror") or msg:match("failed") or msg:match("fatal") then
  --   log.notify(msg, true, vim.log.levels.ERROR, 'UBT')
  --   return
  -- end

  -- warning
  -- if msg:match("[Ww]arning") then
  --   log.notify(msg, true, vim.log.levels.WARN, 'UBT')
  --   return
  -- end
    

  -- info
  -- log.notify(msg, false, vim.log.levels.INFO, 'UBT')
end

local function std_out(_, data)
  if not data then return end

  for _, chunk in ipairs(data) do
    if not chunk or chunk == "" then goto continue end

    -- 改行が含まれているか判定
    if chunk:find("[\r\n]") then
        flush_message(chunk)
    end

    ::continue::
  end
end


local function std_err(_, data)
  if not data then return end
  log.notify(data, true, vim.log.levels.ERROR, 'Job StdError' )
  if progress then
    progress:cancel()
    progress = nil
  end
end

local function std_exit(_, data)
  vim.schedule(function()
    local msg = ('Job exited with code %d'):format(data)

    log.notify(msg, data == 0 and false or true,
                    data == 0 and vim.log.levels.INFO or vim.log.levels.ERROR, 'Job Status')

    if progress then

      if data == 0 then
        progress:finish()
      else
        progress:cancel()
      end
      progress = nil
    end

  end)

end

function M.start(name, cmd)
  local conf = require("UBT.conf")
  message_buffer = ""
  -- Check if fidget.nvim is available
  local fidget_available = pcall(require, 'fidget')
  if fidget_available then
    progress = require('fidget.progress').handle.create({
      message = name,
      lsp_client = { name = "UBT" },
      percentage = 0,
    })
  end

  local job_opts = {
    stdout_buffered = true,
    on_stdout = std_out,
    on_stderr = std_err,
    on_exit = std_exit,
    shell = conf.shell or "cmd",
  }

  vim.fn.jobstart(cmd, job_opts)
end

return M
