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
  ---
  if line == "" then return end

  log.get().info(line)
  
  -- ログファイルへの書き出し
  if current_log_file_handle then
    current_log_file_handle:write(line .. "\n")
    current_log_file_handle:flush()
  end

  -- 1. エラーや警告をログに出力
  if line:match("[Ee]rror") or line:match("failed") or line:match("fatal") then
    return log.get().error(line)
  end
  if line:match("[Ww]arning") then
    return log.get().warn(line)
  end

  -- 2. 進捗情報をUNL.progress UIに送信
  local label, percent_str = line:match("@progress%s+'([^']+)'%s+(%d+)%%")
  if label and percent_str then
    if progress_handle.stage_define then progress_handle:stage_define(label, 100) end
    if progress_handle.stage_update then progress_handle:stage_update(label, tonumber(percent_str), label) end
    return -- 進捗行は通常のログには流さない
  end

  -- 3. それ以外の行は通常のINFOログとして出力
  -- log.get().info(line)
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

      -- ★★★ ここからが変更点 ★★★

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
      
      -- ★★★ ここまでが変更点 ★★★

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
