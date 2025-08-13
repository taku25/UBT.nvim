-- job.runner.lua (Powered by the new Logger Architecture)

local M = {}

local logger = require("UBT.logger")

-- ストリームバッファ（これはrunnerの責務として残す）
local stdout_buffer = ""

--- 受け取った一行を解析し、適切なイベントをloggerにディスパッチする
local function process_line(line)
  line = line:match("^%s*(.-)%s*$") -- trim
  if line == "" then return end

  -- 1. エラーを検出したら、'write'イベントを発行
  if line:match("[Ee]rror") or line:match("failed") or line:match("fatal") then
    logger.write(line, vim.log.levels.ERROR)
    return
  end

  -- 2. ワーニングを検出したら、'write'イベントを発行
  if line:match("[Ww]arning") then
    logger.write(line, vim.log.levels.WARN)
    return
  end

  -- 3. プログレスを検出したら、'on_progress_update'イベントを発行
  local label, percent_str = line:match("@progress%s+'([^']+)'%s+(%d+)%%")
  if label and percent_str then
    logger.on_progress_update(label, tonumber(percent_str))
  end

  -- 4. 上記のいずれでもなければ、それは通常のINFOレベルのログ
  --    'write'イベントを発行
  logger.write(line, vim.log.levels.INFO)
end

--- on_stdout: ストリームデータを安全に一行ずつに分割する
local function on_stdout(_, data)
  if not data then return end
  local incoming_data = stdout_buffer .. table.concat(data, "")
  local lines = vim.split(incoming_data, "[\r\n]+", { plain = false, trimempty = true })
  if not incoming_data:match("[\r\n]$") and #lines > 0 then
    stdout_buffer = table.remove(lines)
  else
    stdout_buffer = ""
  end

  for _, line in ipairs(lines) do
    if line and line ~= "" then
      process_line(line)
    end
  end
end

--- on_exit: ジョブ終了時に、バッファをフラッシュし、'on_job_exit'イベントを発行する
local function on_exit(_, code)
  vim.schedule(function()
    -- バッファに残った最後のデータを処理
    if stdout_buffer and stdout_buffer ~= "" then
      process_line(stdout_buffer)
    end

    logger.on_job_exit(code)

    -- 状態リセット（バッファだけで良くなる）
    stdout_buffer = ""
  end)
end

--- M.start: ジョブを開始し、loggerに'on_job_start'イベントを発行する
function M.start(name, cmd)
  -- 状態をリセット
  stdout_buffer = ""

  -- これにより、各writerが自分自身の初期化処理を行う
  logger.on_job_start({ name = name })

  local job_opts = {
    stdout_buffered = true,
    on_stdout = on_stdout,
    on_stderr = on_stdout, -- stderrも同じように処理するなら、on_stdoutを使い回せる
    on_exit = on_exit,
  }

  return vim.fn.jobstart(cmd, job_opts)
end

return M
