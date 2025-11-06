-- lua/UBT/model.lua (旧picker_model.lua)

-- ★ 変更点: 新しいリファクタリング済みのpathモジュールをrequire
local ubt_path = require("UBT.path")
local log = require("UBT.logger")
local provider = require("UNL.provider")
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

-- [!] UEPプロバイダーから動的ターゲットを取得し、preset形式に変換するヘルパー
local function get_current_os_platform()
    if vim.fn.has("win32") == 1 then return "Win64" end
    if vim.fn.has("mac") == 1 then return "Mac" end
    if vim.fn.has("unix") == 1 then return "Linux" end
    return nil
end

---
-- UEPプロバイダーから動的ターゲットを取得し、preset形式に変換する
local function get_dynamic_targets_from_uep()
  local logger = log.get()
  local conf = get_config()

  -- [!] 1. UEPからターゲットリストを取得 (2つの変数で受け取る)
  local ok_provider, targets_from_uep = provider.request("uep.get_build_targets")
  
  if not ok_provider or not targets_from_uep or #targets_from_uep == 0 then
    logger.debug("UEP provider returned no dynamic targets (ok: %s).", tostring(ok_provider))
    return {}
  end
  
  logger.info("Received %d build targets from UEP provider.", #targets_from_uep)

  -- ( ... 2a, 2b, 2c, 2d, 2e ... OS/SDK/Configの決定ロジックは変更なし)
  local base_platform = get_current_os_platform()
  local all_available_platforms = {}
  if base_platform then all_available_platforms[base_platform] = true end
  for _, sdk_platform in ipairs(conf.has_sdks or {}) do
    all_available_platforms[sdk_platform] = true
  end
  local editor_platforms_list = {}
  if base_platform then table.insert(editor_platforms_list, base_platform) end
  local game_platforms_list = vim.tbl_keys(all_available_platforms)
  local configs_editor = { "Development", "DebugGame" }
  local configs_game_or_program = { "Development", "DebugGame", "Shipping" }

  local dynamic_presets = {}

  -- 3. UEPのリストとUBTの標準リストを組み合わせる
  for _, target_info in ipairs(targets_from_uep) do
    local target_name = target_info.name -- "UnrealEditor" や "Relocator"
    local target_type = target_info.type
    
    local platforms_to_use
    local configs_to_use
    local is_editor = false
    
    if target_type == "Editor" then
      platforms_to_use = editor_platforms_list
      configs_to_use = configs_editor
      is_editor = true
    else
      platforms_to_use = game_platforms_list
      configs_to_use = configs_game_or_program
      is_editor = false
    end
    
    for _, platform in ipairs(platforms_to_use) do
      for _, config in ipairs(configs_to_use) do
        
        -- ▼▼▼【ここが重要】▼▼▼
        table.insert(dynamic_presets, {
          -- "name" はピッカーに表示するラベル
          name = string.format("%s %s %s", target_name, platform, config),
          
          -- "TargetName" は UBT が実際に必要とするターゲット名
          TargetName = target_name,
          
          Platform = platform,
          IsEditor = is_editor,
          Configuration = config
        })
        -- ▲▲▲【修正完了】▲▲▲
      end
    end
  end
  
  return dynamic_presets
end


---
-- 設定からビルドプリセットを取得し、動的ターゲットとマージする
function M.get_presets()
  local conf = get_config()
  local log_instance = log.get()

  -- 1. Config から静的な presets (ユーザー定義) を取得
  local static_presets = conf.presets or {}
  log_instance.debug("Loaded %d static presets from config.", #static_presets)

  -- 2. UEPプロバイダーから動的な presets を取得 (安全に pcall でラップ)
  local ok, dynamic_presets = pcall(get_dynamic_targets_from_uep)
  if not ok then
      log_instance.warn("Failed to get dynamic targets from UEP provider: %s", tostring(dynamic_presets))
      dynamic_presets = {}
  end

  -- 3. リストを結合（ユーザー定義の静的プリセットを優先）
  local combined_presets = {}
  local seen_names = {}

  -- 最初に静的プリセットを追加
  for _, preset in ipairs(static_presets) do
      if preset.name and not seen_names[preset.name] then
          table.insert(combined_presets, preset)
          seen_names[preset.name] = true
      end
  end
  
  log_instance.debug("Added %d static presets to final list.", #combined_presets)

  -- 次に、まだリストにない動的プリセットを追加
  local dynamic_added_count = 0
  for _, preset in ipairs(dynamic_presets) do
      if preset.name and not seen_names[preset.name] then
          table.insert(combined_presets, preset)
          seen_names[preset.name] = true
          dynamic_added_count = dynamic_added_count + 1
      end
  end
  
  log_instance.debug("Added %d new dynamic presets to final list.", dynamic_added_count)
  
  return combined_presets
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
