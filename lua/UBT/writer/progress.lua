--- Writer backend for managing the fidget.nvim progress UI.
-- This module implements the "Writer" interface and is responsible
-- for creating, updating, and finishing progress bars based on
-- events dispatched from the logger.
local M = {}

local path = require("UBT.path")

-- このwriterが管理する、すべてのアクティブなfidgetハンドルを格納する
-- { ["UBT:MainTask"] = handle, ["Compiling C++"] = handle, ... }
local active_handles = {}
local main_handle_key = "UBT:MainTask"
-- どのハンドルに詳細メッセージを送るべきかを追跡する
local last_updated_label = nil

-- fidgetが利用可能かどうかをキャッシュする
local fidget_available = false

local progress_log_path = nil
-- "Writer" interface implementation
--
-- ジョブ開始時に、親となるメインのプログレスバーを作成する
function M.on_job_start(opts)
  progress_log_path = path.get_progress_log_file_path()
  
  -- これにより、ファイルの中身が毎回空になる
  local file, err = io.open(progress_log_path, "w")
  if file then
    file:write(string.format("--- Job '%s' started at %s ---\n", opts.name, os.date()))
    file:close()
  else
    vim.api.nvim_err_writeln("UBT.nvim: Failed to clear progress log file: " .. tostring(err))
  end

  active_handles = {} -- 古いハンドルをクリア
  last_updated_label = nil
  fidget_available = pcall(require, 'fidget')

  if fidget_available then
    -- ジョブ全体の親タスクとして、メインハンドルを作成
    local handle = require('fidget.progress').handle.create({
      title = opts.name,
      lsp_client = { name = "UBT" },
    })

    active_handles[main_handle_key] = handle --最初はメインハンドルがアクティブ
    last_updated_label = handle -- 最初はメインハンドルがアクティブ
  end
end

-- ジョブ終了時に、残っているすべてのプログレスバーを後片付けする
function M.on_job_exit(code)
  if not fidget_available then return end

  for _, handle in pairs(active_handles) do
    if code == 0 then
      -- 100%に達していなくても、成功したならfinish()を呼ぶ
      handle:finish()
    else
      handle:cancel()
    end
  end
  -- 状態をリセット
  active_handles = {}
  last_updated_label = nil
end

-- 進捗更新時に呼ばれ、サブタスクのバーを作成・更新する
function M.on_progress_update(label, percentage)
  if not fidget_available then return end

  local handle = active_handles[label]
  -- このサブタスクのハンドルがなければ、新しく作る
  if not handle then
    handle = require('fidget.progress').handle.create({
      title = label,
      lsp_client = { name = "UBT" },
    })
    active_handles[label] = handle
  end
  
  -- パーセンテージを更新
  handle:report({ percentage = percentage })
  -- このサブタスクが、今一番アクティブであると記録する
  last_updated_label = label
end

-- 通常のログメッセージ書き込み時に呼ばれる
function M.write(message, level)
  if not fidget_available then return end
  
  -- INFOレベルのメッセージだけを、直近のプログレスバーの詳細として表示する
  if level == vim.log.levels.INFO then
    local handle_to_update = active_handles[last_updated_label]
    if handle_to_update then
      handle_to_update:report({ message = message })
    end
  end
end

return M
