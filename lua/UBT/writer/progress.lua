--- Writer backend for managing the fidget.nvim progress UI.
-- This module implements the "Writer" interface and is responsible
-- for creating, updating, and finishing progress bars based on
-- events dispatched from the logger.
local M = {}

local path = require("UBT.path")
local util = require("UBT.writer.util")
local conf = require("UBT.conf")

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
local function write_to_file(condition, text)
  if not progress_log_path then return end
  local file, err = io.open(progress_log_path, condition)
  if file then
    file:write(text .. "\n")
    file:close()
  else
    vim.api.nvim_err_writeln("UBT.nvim: Failed to clear progress log file: " .. tostring(err))
  end
end
-- ジョブ開始時に、親となるメインのプログレスバーを作成する
function M.on_job_start(opts)
  
  write_to_file("w",string.format("--- Job '%s' started at %s ---\n", opts.name, os.date()))

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
  if fidget_available then

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
end


function M.on_plugin_setup(config)
  progress_log_path = path.get_progress_log_file_path()

  local file, err = io.open(progress_log_path, "w")
  if file then
    file:write(string.format("\n--- UBT.nvim Progress Session Started at %s ---\n", os.date()))
    file:close()
  else
    vim.api.nvim_err_writeln("UBT.nvim: Failed to open persistent log file: " .. tostring(err))
  end
end

-- 通常のログメッセージ書き込み時に呼ばれる
function M.write(message, level)
  local level_str = util.level_to_string(level)
  local timestamp = os.date("[%Y-%m-%d %H:%M:%S]")
  local formatted_message = string.format("%s [%s] %s", timestamp, level_str, message)

  if fidget_available then
    --progressはstateをみて
    if conf.progress_level ~= "NONE" and util.should_display(level, conf.progress_level) then
      local handle_to_update = active_handles[last_updated_label]
      if handle_to_update then
        handle_to_update:report({ message = formatted_message })
      end
    end
  end

  --fileにはすべて記入
  write_to_file("a", formatted_message)
  

end



return M
