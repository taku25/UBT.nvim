-- lua/UBT/writer/progress_log.lua

local ubt_path = require("UBT.path")

local M = {}

function M.new()
  local self = {}
  local log_path

  -- このwriterが書き込むべきログファイルのパスを取得する
  local function resolve_path()
    if log_path then return log_path end
    log_path = ubt_path.get_progress_log_file_path()
    return log_path
  end

  -- UNL.loggingから呼び出されるwrite関数
  function self.write(msg_level, message, ctx)
    ctx = ctx or {}
    local path = resolve_path()
    if not path then return end

    -- UBTのジョブランナーは、進捗行をINFOレベルでログに流している
    -- なので、INFOレベルのログの中から、進捗を表す "@progress" を含む行だけをフィルタリングする
    -- if msg_level == vim.log.levels.INFO and message:match("@progress") then
      local file, err = io.open(path, "a")
      if file then
        file:write(message .. "\n")
        file:close()
      end
    -- end
  end

  -- ジョブ開始時にログファイルをクリアする
  function self.on_job_start(opts)
    local path = resolve_path()
    if not path then return end
    -- "w"モードで開くことで、ファイルをクリアする
    local file, err = io.open(path, "w")
    if file then
      file:write(string.format("--- Job '%s' started at %s ---\n", opts.name, os.date()))
      file:close()
    end
  end

  return self
end

return M
