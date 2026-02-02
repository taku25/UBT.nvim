-- lua/UBT/model.lua (旧picker_model.lua)

local ubt_path = require("UBT.path")
local log = require("UBT.logger")

-- UNLのシステムから設定を取得するヘルパー
local function get_config()
  return require("UNL.config").get("UBT")
end

local M = {}

-- ログ行を解析するロジック
M.line_info = function(line)
  local file_path, row, col, message
  local full_path_with_prefix, captured_row, captured_message = line:match("(.-)%((%d+)%):%s*(.*)")

  if full_path_with_prefix and captured_row then
    row = tonumber(captured_row)
    message = captured_message
    local path_start_pos = full_path_with_prefix:match("()[A-Za-z]:[\\/]") -- Windows
                         or full_path_with_prefix:match("()/" )            -- POSIX
    if path_start_pos then
      file_path = full_path_with_prefix:sub(path_start_pos)
    else
      file_path = full_path_with_prefix
    end
  end

  return {
    display_text = line, 
    row_message = message or line, 
    file_path = file_path,
    row = row,
    col = col,
  }
end

-- 診断ログの生データをファイルから読み込む
M.get_row_data = function()
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

-- UNL APIから動的ターゲットを取得し、preset形式に変換するヘルパー
local function get_current_os_platform()
    if vim.fn.has("win32") == 1 then return "Win64" end
    if vim.fn.has("mac") == 1 then return "Mac" end
    if vim.fn.has("unix") == 1 then return "Linux" end
    return nil
end

---
-- UNL APIから動的ターゲットを取得し、preset形式に変換する (Async)
local function get_dynamic_targets_async(callback)
  local logger = log.get()
  local conf = get_config()
  local unl_api = require("UNL.api")

  -- [!] 1. UNLからターゲットリストを取得
  unl_api.db.get_build_targets(function(targets, err)
      if err or not targets or #targets == 0 then
        logger.debug("UNL provider returned no dynamic targets (err: %s).", tostring(err))
        return callback({})
      end
      
      logger.info("Received %d build targets from UNL provider.", #targets)

      local base_platform = get_current_os_platform()
      local all_available_platforms = {}
      if base_platform then all_available_platforms[base_platform] = true end
      for _, sdk_platform in ipairs(conf.has_sdks or {}) do
        all_available_platforms[sdk_platform] = true
      end
      local editor_platforms_list = {}
      if base_platform then table.insert(editor_platforms_list, base_platform) end
      local game_platforms_list = vim.tbl_keys(all_available_platforms)
      local configs_editor = { "Development", "DebugGame", "Debug" }
      local configs_game_or_program = { "Development", "DebugGame", "Debug", "Test", "Shipping" }

      local dynamic_presets = {}

      -- 3. リストを組み合わせる
      for _, target_info in ipairs(targets) do
        local target_name = target_info.name
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
            table.insert(dynamic_presets, {
              name = string.format("%s %s %s", target_name, platform, config),
              TargetName = target_name,
              Platform = platform,
              IsEditor = is_editor,
              Configuration = config
            })
          end
        end
      end
      
      callback(dynamic_presets)
  end)
end


---
-- 設定からビルドプリセットを取得し、動的ターゲットとマージする (Async)
function M.get_presets(callback)
  local conf = get_config()
  local log_instance = log.get()

  -- 1. Config から静的な presets (ユーザー定義) を取得
  local static_presets = conf.presets or {}
  log_instance.debug("Loaded %d static presets from config.", #static_presets)

  -- 2. UNL APIから動的な presets を取得
  get_dynamic_targets_async(function(dynamic_presets)
      -- 3. リストを結合（ユーザー定義の静的プリセットを優先）
      local combined_presets = {}
      local seen_names = {}

      for _, preset in ipairs(static_presets) do
          if preset.name and not seen_names[preset.name] then
              table.insert(combined_presets, preset)
              seen_names[preset.name] = true
          end
      end
      
      log_instance.debug("Added %d static presets to final list.", #combined_presets)

      local dynamic_added_count = 0
      for _, preset in ipairs(dynamic_presets) do
          if preset.name and not seen_names[preset.name] then
              table.insert(combined_presets, preset)
              seen_names[preset.name] = true
              dynamic_added_count = dynamic_added_count + 1
          end
      end
      
      log_instance.debug("Added %d new dynamic presets to final list.", dynamic_added_count)
      
      callback(combined_presets)
  end)
end

-- ビルドプリセットの名前リストを取得する (Async)
function M.get_presets_names(callback)
  M.get_presets(function(presets)
      local preset_names = {}
      for _, preset in ipairs(presets) do
        table.insert(preset_names, preset.name)
      end
      callback(preset_names)
  end)
end

return M