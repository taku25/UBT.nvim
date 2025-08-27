-- lua/UBT/model.lua (旧picker_model.lua)

-- ★ 変更点: 新しいリファクタリング済みのpathモジュールをrequire
local ubt_path = require("UBT.path")

-- ★ 変更点: UNLのシステムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-- ログ行を解析するロジック（この関数は自己完結しているので変更なし）
-- ログ行を解析して、ファイルパス、行番号、メッセージなどの情報を抽出する
-- 新しいフォーマット例: "[ERROR][UBT] C:\path\to\file.h(13): Error: Some message"
-- @param line string
-- @return table
M.line_info = function(line)
  local file_path, row, col, message

  -- 1. 正規表現でファイルパス、行番号、メッセージ本体を一度にキャプチャする
  -- パターン解説:
  -- (.-)        : ファイルパス部分。非貪欲マッチ。
  -- %(          : リテラルの開き括弧 '('.
  -- (%d+)       : 行番号。1桁以上の数字をキャプチャする。
  -- %)          : リテラルの閉じ括弧 ')'.
  -- :%s*        : コロンと、それに続く0個以上の空白文字。
  -- (.*)        : メッセージの残りすべて。
  local full_path_with_prefix, captured_row, captured_message = line:match("(.-)%((%d+)%):%s*(.*)")

  if full_path_with_prefix and captured_row then
    -- 2. パスと行番号が見つかった場合
    row = tonumber(captured_row)
    message = captured_message

    -- 3. キャプチャしたパスから、先頭のログプレフィックス ([INFO][UBT]など) を取り除く
    --    Windowsパス (C:\) または POSIXパス (/) の開始位置を探す
    local path_start_pos = full_path_with_prefix:match("()[A-Za-z]:[\\/]") -- Windows
                         or full_path_with_prefix:match("()/")             -- POSIX
    
    if path_start_pos then
      file_path = full_path_with_prefix:sub(path_start_pos)
    else
      -- パス形式が見つからない場合は、プレフィックスがないと仮定
      file_path = full_path_with_prefix
    end

  end

  -- 4. 最終的な情報をテーブルにまとめて返す
  return {
    -- 表示用テキスト: 元の行をそのまま使うのが分かりやすい
    display_text = line, 
    -- メッセージ本体: ファイルパスと行番号を除いた部分
    row_message = message or line, 
    file_path = file_path, -- 見つかったファイルパス
    row = row,             -- 見つかった行番号
    col = col,             -- このフォーマットには桁番号はないので nil のまま
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
