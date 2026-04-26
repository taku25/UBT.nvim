-- lua/UBT/job/runner.lua (UNLベースにリファクタリング)

local unl_log = require("UNL.logging")
local log = require("UBT.logger")
local unl_progress = require("UNL.backend.progress")

local provider = require("UNL.provider") --- ★ 変更点: providerをrequire


local context = require("UBT.context")
local ubt_path = require("UBT.path")
local function get_config()
  return require("UNL.config").get("UBT")
end
local M = {}

local current_job_id = nil
local current_log_file_handle = nil

-- 現在のジョブの集計値
local job_metrics = {
  error_count   = 0,
  warning_count = 0,
}

-- -----------------------------------------------------------------------
-- エラー／警告行の判定
-- -----------------------------------------------------------------------

-- MSVC: "foo.cpp(10): error C2065:"  "LINK : fatal error LNK1120:"
-- UBT:  "ERROR: could not find ..."
local function is_error_line(line)
  if line:match(":%s*error%s+[A-Z%d]")   then return true end
  if line:match(":%s*fatal%s+error%s+")  then return true end
  if line:match("^ERROR%s*:")            then return true end
  if line:match("^Build FAILED")         then return true end
  return false
end

-- MSVC: "foo.cpp(10): warning C4101:"
-- UBT:  "WARNING: ..."
local function is_warning_line(line)
  if line:match(":%s*warning%s+[A-Z%d]") then return true end
  if line:match("^WARNING%s*:")          then return true end
  return false
end

---
-- 実行中のジョブを停止する
function M.stop()
  if current_job_id then
    vim.fn.jobstop(current_job_id)
    log.get().info("UBT job cancelled.")
    current_job_id = nil
    if current_log_file_handle then
      current_log_file_handle:write("\n--- Job Cancelled ---\n")
      current_log_file_handle:close()
      current_log_file_handle = nil
    end
    return true
  end
  return false
end

---
-- ジョブの標準出力を一行ずつ処理するヘルパー
-- @param line string
-- @param progress_handle table UNL.progressのインスタンス
local function process_line(line, progress_handle)
  if line == "" then return end

  log.get().info(line)

  -- ログファイルへの書き出し
  if current_log_file_handle then
    current_log_file_handle:write(line .. "\n")
    current_log_file_handle:flush()
  end

  -- 1. エラー／警告を判定してカウント＆ログ出力
  if is_error_line(line) then
    job_metrics.error_count = job_metrics.error_count + 1
    return log.get().error(line)
  end
  if is_warning_line(line) then
    job_metrics.warning_count = job_metrics.warning_count + 1
    return log.get().warn(line)
  end

  -- 2. 進捗情報をUNL.progress UIに送信
  local label, percent_str = line:match("@progress%s+'([^']+)'%s+(%d+)%%")
  if label and percent_str then
    if progress_handle.stage_define then progress_handle:stage_define(label, 100) end
    if progress_handle.stage_update then progress_handle:stage_update(label, tonumber(percent_str), label) end
    return -- 進捗行は通常のログには流さない
  end
end

---
-- 非同期ジョブを開始する
-- @param name string ジョブの名前 (UIのタイトルになる)
-- @param cmd table 実行するコマンド
function M.start(name, cmd, opts)
  if not cmd or type(cmd) ~= "table" or #cmd == 0 then
    return log.get().error("Job runner received an invalid or empty command for job: %s. This might be due to a failure in finding the project or engine.", name)
  end

  -- 既存のジョブがあれば停止（念のため）
  M.stop()

  -- カウンターをリセット
  job_metrics.error_count   = 0
  job_metrics.warning_count = 0

  local stdout_buffer = ""

  -- ジョブを開始する直前に、"on_job_start" イベントを全てのwriterに通知する
  unl_log.dispatch_event("UBT", "on_job_start", { name = name })

  local log_path = ubt_path.get_progress_log_file_path()
  current_log_file_handle = io.open(log_path, "w")
  if current_log_file_handle then
    current_log_file_handle:write("--- Job '" .. name .. "' started at " .. os.date() .. " ---\n")
    current_log_file_handle:write("CMD: " .. table.concat(cmd, " ") .. "\n")
    current_log_file_handle:write("----------------------------------------------------------\n")
    current_log_file_handle:flush()
  end

  provider.notify("ulg.build_log", {
    clear = true,
    log_path = log_path,
    title = "[[ UBT " .. name .. " LOG ]]"
  })

  -- 1. UNLの進捗UIインスタンスを作成
  local conf = require("UNL.config").get("UBT")
  local progress, _ = unl_progress.create_for_refresh(conf,
  {
    title = name,
    client_name = "UEP"
  })

  progress:open()
  log.get().debug("Job starting: %s", table.concat(cmd, " "))

  -- 2. jobstartのコールバックを定義
  local on_stdout = function(_, data)
    if not data then return end

    local concat_char = ""
    if vim.fn.has('win32') ~= 1 then
      concat_char = "\n"
    end
    local incoming_data = stdout_buffer .. table.concat(data, concat_char)
    local lines = vim.split(incoming_data, "[\r\n]+", { plain = false, trimempty = true })
    if not incoming_data:match("[\r\n]$") and #lines > 0 then
      stdout_buffer = table.remove(lines)
    else
      stdout_buffer = ""
    end

    for _, line in ipairs(lines) do
      if line and line ~= "" then
        process_line(line, progress)
      end
    end
  end

  local on_exit = function(_, code)
    vim.schedule(function()
      current_job_id = nil
      if current_log_file_handle then
        current_log_file_handle:close()
        current_log_file_handle = nil
      end

      if stdout_buffer and stdout_buffer ~= "" then
        process_line(stdout_buffer, progress)
      end
      
      local success = (code == 0)
      progress:finish(success)

      -- ビルドサマリーを通知
      if success then
        local msg
        if job_metrics.warning_count > 0 then
          msg = string.format("[UBT] %s succeeded — %d warning(s)", name, job_metrics.warning_count)
          vim.notify(msg, vim.log.levels.WARN)
        else
          msg = string.format("[UBT] %s succeeded", name)
          vim.notify(msg, vim.log.levels.INFO)
        end
      else
        local msg = string.format("[UBT] %s FAILED — %d error(s), %d warning(s)",
          name, job_metrics.error_count, job_metrics.warning_count)
        vim.notify(msg, vim.log.levels.ERROR)
      end

      -- 1. 完了時のペイロードを一度だけ生成する
      local result_payload = { success = success }

      if success == true and opts.label then
        -- 設定フラグ(use_last_preset_as_default)に関わらず、
        -- 常にコンテキストに保存する
        context.set("last_preset", opts.label)
        log.get().debug("Saved last preset to context: %s", opts.label)
      end

      -- 2. (内部用) イベント発行のための on_finish を呼び出す
      if opts and opts.on_finish then
        opts.on_finish(result_payload)
      end

      -- 3. (外部用) カスタム処理のための on_complete を呼び出す
      if opts and opts.on_complete then
        opts.on_complete(result_payload)
      end

      log.get().info("Job '%s' finished with code %d", name, code)
      unl_log.dispatch_event("UBT", "on_job_finish", { name = name })
    end)
  end

  -- 4. ジョブを開始
  current_job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = false,
    on_stdout = on_stdout,
    on_stderr = on_stdout, -- stderrも同じように処理
    on_exit = on_exit,
  })
  return current_job_id
end

return M
