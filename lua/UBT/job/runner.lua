-- job.runner.lua (Stream-safe Final Version)

local M = {}
local log = require("UBT.log")

-- ハンドル管理用のテーブル
local active_progress_handles = {}
local main_handle_key = "UBT:MainTask" -- よりユニークなキー名にocal main_handle_key = "main_handle"
local last_updated_handle = nil


-- stream buffer
local stdout_buffer = ""

-- process_line 関数は、必ず「完全な一行」を受け取る前提なので変更なし
local function process_line(line)
  line = line:match("^%s*(.-)%s*$")
  if line == "" then return end

  -- エラーやワーニングを最優先で処理し、通知したら即座にreturnする
  if line:match("[Ee]rror") or line:match("failed") or line:match("fatal") then
    log.notify(line, true, vim.log.levels.ERROR, 'UBT')
    return -- 通知したので、以降のプログレス処理は行わない
  end
  if line:match("[Ww]arning") then
    log.notify(line, true, vim.log.levels.WARN, 'UBT')
    return
  end

  -- 1. `@progress` 行を解析 (ここは変更なし)
  local label, percent_str = line:match("@progress%s+'([^']+)'%s+(%d+)%%")
  if label and percent_str then
    local percent = tonumber(percent_str)
    local handle = active_progress_handles[label]
    if not handle and pcall(require, 'fidget') then
      handle = require('fidget.progress').handle.create({
        title = label,
        lsp_client = { name = "UBT" },
        percentage = 0,
      })
      active_progress_handles[label] = handle
    end
    if handle then
      handle:report({ message = label, percentage = percent })
      last_updated_handle = handle
    end
    return
  end

  -- 2. `@progress` が付いていない、その他のログ行の処理
  local write_handle = last_updated_handle or active_progress_handles[main_handle_key]
  if write_handle then
    write_handle:report({ message = line })
  end
end

-- on_stdout: (CR | LF) のいずれかで分割する、真の最終版
local function on_stdout(_, data)


  if not data then return end


  local incoming_data = stdout_buffer .. table.concat(data, "")

  -- これにより、\r または \n、あるいはその両方が、区切り文字として扱われる
  -- plain = false にして、第2引数を正規表現パターンとして解釈させる
  local lines = vim.split(incoming_data, "[\r\n]+", { plain = false, trimempty = true })

  -- `trimempty` を使っても、最後の不完全な行を処理する必要がある
  -- データが改行で終わっていない場合、最後の要素は不完全な行
  if not incoming_data:match("[\r\n]$") and #lines > 0 then
    stdout_buffer = table.remove(lines)
  else
    stdout_buffer = ""
  end

  for _, line in ipairs(lines) do
    if line and line ~= "" then
      -- log.notify(line, true, vim.log.levels.INFO)
      -- process_lineに渡す前に、念のため前後の空白を除去する
      process_line(line:match("^%s*(.-)%s*$"))
    end
  end
end


local function on_exit(_, code)
  vim.schedule(function()
    if stdout_buffer and stdout_buffer ~= "" then process_line(stdout_buffer) end

    local msg = ('Job exited with code %d'):format(code)
    local level = (code == 0) and vim.log.levels.INFO or vim.log.levels.ERROR
    log.notify(msg, (code == 0) and false or true, level, 'Job Status')

    -- 一つのループですべてのハンドルを処理する
    for _, handle in pairs(active_progress_handles) do
      if code == 0 then
        handle:finish()
      else
        handle:cancel()
      end
    end

    -- 状態を完全にリセット
    active_progress_handles = {}
    last_updated_handle = nil
    stdout_buffer = ""
  end)
end


function M.start(name, cmd)
  -- 状態をリセット (ここは変更なし)
  active_progress_handles = {}
  last_updated_handle = nil
  stdout_buffer = ""

  -- main_handleの作成 (ここは変更なし)
  if pcall(require, 'fidget') then
    active_progress_handles[main_handle_key] = require('fidget.progress').handle.create({
      title = name,
      lsp_client = { name = "UBT" },
    })
  end

  -- job_optsとjobstartの呼び出し (ここは変更なし)
  local job_opts = {
    stdout_buffered = true,
    on_stdout = on_stdout,
    on_stderr = on_stderr, -- on_stderrもバッファリング対応推奨
    on_exit = on_exit,
  }
  vim.fn.jobstart(cmd, job_opts)
end

return M
