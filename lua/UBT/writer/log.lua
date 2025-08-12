--- Writer backend for persisting all logs to a file.
-- This module implements the "Writer" interface and is responsible
-- for detailed, persistent logging for debugging purposes.
local M = {}

local path = require("UBT.path")
local conf = require("UBT.conf")

local log_path = nil

local function write_to_file(text)
  if not log_path then return end
  local file, err = io.open(log_path, "a")
  if file then
    file:write(text .. "\n")
    file:close()
  else
    vim.api.nvim_err_writeln("UBT.nvim: Failed to write to log file: " .. tostring(err))
  end
end

-- "Writer" interface implementation
-------------------------------------
---
function M.on_plugin_setup(config)
  -- 自分のログファイルのパスを確定させる
  log_path = path.get_log_file_path(config.log_file_name)
  
  -- これにより、ファイルが存在すれば、続きから書き始める
  -- Neovimを再起動しても、ログは消えない！
  local file, err = io.open(log_path, "a")
  if file then
    file:write(string.format("\n--- UBT.nvim Session Started at %s ---\n", os.date()))
    file:close()
  else
    vim.api.nvim_err_writeln("UBT.nvim: Failed to open persistent log file: " .. tostring(err))
  end
end

-- ジョブ開始時に呼ばれる
-- on_job_start: ジョブ開始をログに記録する
function M.on_job_start(opts)
  M.write(string.format("Job '%s' starting...", opts.name), vim.log.levels.INFO)
end

-- on_job_exit: ジョブ終了をログに記録する
function M.on_job_exit(code)
  M.write(string.format("Job finished with code %d", code), vim.log.levels.INFO)
end

-- on_progress_update: プログレスも、ただのINFOログとして記録する
function M.on_progress_update(label, percentage)
  M.write(string.format("@progress '%s' %d%%", label, percentage), vim.log.levels.INFO)
end

-- write: すべてのメッセージを、タイムスタンプ付きで書き込む
function M.write(message, level)
  if not log_path then return end
  
  local level_str = vim.log.levels[level] or "UNKNOWN"
  local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
  local formatted_message = string.format("%s [%s] %s", timestamp, level_str, message)
  
  local file = io.open(log_path, "a")
  if file then
    file:write(formatted_message .. "\n")
    file:close()
  end
end

return M
