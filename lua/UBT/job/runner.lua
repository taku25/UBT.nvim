-- UBT.nvim: Neovim command registration module
-- job.runner.lua

local M = {}
local uv = vim.loop

local log = require("UBT.log")

local progress = nil

local function std_out(_, data)
  if not data then return end

  for _, line in ipairs(data) do
    -- @progress のみ処理
    local label, percent = line:match("@progress%s+'([^']+)'%s+(%d+)%%")
    if label then
      if label and percent then
        -- 通常ログ出力（@progress 以外）
        log.notify(label, vim.log.levels.INFO, 'Job Output')
        -- シングルクォート除去済みのラベルと数値化されたパーセンテージ
        if progress then
          progress:report({
            message = label,
            percentage = tonumber(percent),
          })
        end
      end
    end
  end
end


local function std_err(_, data)
  if data and next(data) then
    log.notify(data, vim.log.levels.ERROR, 'Job StdError' )
  end
  if progress then
    progress:cancel()
    progress = nil
  end
end

local function std_exit(_, data)
  vim.schedule(function()
    local msg = ('Job exited with code %d'):format(data)

    log.notify(msg, data == 0 and vim.log.levels.INFO or vim.log.levels.ERROR, 'Job Status')

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
