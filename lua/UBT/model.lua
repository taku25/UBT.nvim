-- lua/UBT/model.lua (旧picker_model.lua)

-- ★ 変更点: 新しいリファクタリング済みのpathモジュールをrequire
local ubt_path = require("UBT.path")

-- ★ 変更点: UNLのシステムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-- ログ行を解析するロジック（この関数は自己完結しているので変更なし）
M.line_info = function(line)
  local clean_line = line:gsub("^%[.-%]%s*", "")
  local level, rest = clean_line:match("^%[(%u+)%]%s+(.*)")
  rest = rest or clean_line

  local file_path, row, col
  if level == "ERROR" or level == "WARN" then
    file_path, row, col = rest:match("^(.-)%((%d+),(%d+)%)")
  end

  return {
    display_text = clean_line,
    row_message = rest,
    file_path = file_path,
    row = tonumber(row),
    col = tonumber(col),
  }
end

-- 診断ログの生データをファイルから読み込む
M.get_row_data = function()
  -- ★ 変更点: 古いconf.load_config()は不要
  local log_file = ubt_path.get_progress_log_file_path()
  local lines = vim.fn.filereadable(log_file) == 1 and vim.fn.readfile(log_file) or {}

  if #lines == 0 then
    return nil, "UBT: No diagnostics found in log file."
  end
  return lines, nil
end

-- 診断データを解析済みのテーブルとして取得する
M.get_diagnostics = function()
  local diagnostics_data = {}
  local lines, err = M.get_row_data()
  if err then
    return nil, err
  end
  for _, line in ipairs(lines) do
    table.insert(diagnostics_data, M.line_info(line))
  end
  return diagnostics_data, nil
end

-- 設定からビルドプリセットを取得する
function M.get_presets()
  -- ★ 変更点: UNL経由で設定を取得
  local conf = get_config()
  return conf.presets or {}
end

-- ビルドプリセットの名前リストを取得する
function M.get_presets_names()
  local preset_names = {}
  for _, preset in ipairs(M.get_presets()) do
    table.insert(preset_names, preset.name)
  end
  return preset_names
end

return M
