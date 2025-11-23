-- lua/UBT/cmd/run.lua

local unl_finder = require("UNL.finder")
local log = require("UBT.logger")
local fs = require("vim.fs")
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")
local context = require("UBT.context")

local M = {}

local function get_config()
  return require("UNL.config").get("UBT")
end

-- プリセット名からプリセットオブジェクトを取得するヘルパー
local function get_preset_by_name(name)
  local presets = model.get_presets()
  for _, p in ipairs(presets) do
    if p.name == name then
      return p
    end
  end
  return nil
end

-- スタンドアロンバイナリを起動する関数
local function run_standalone(project_info, preset)
  local logger = log.get()
  logger.info("Running standalone build with preset: %s", preset.name)
  
  local project_name = vim.fn.fnamemodify(project_info.uproject, ":t:r")
  
  local binary_name_parts = {
    project_name,
    preset.Platform,
  }
  
  -- 'Development' ではない場合のみ、コンフィグレーション名をファイル名に追加
  if preset.Configuration ~= "Development" then
    table.insert(binary_name_parts, preset.Configuration)
  end

  local binary_name = table.concat(binary_name_parts, "-") .. ".exe"
  
  local binary_path = fs.joinpath(project_info.root, "Binaries", preset.Platform, binary_name)

  if vim.fn.executable(binary_path) ~= 1 then
    return logger.error("Standalone binary not found or not executable: %s", binary_path)
  end
  
  logger.info("Executing: %s", binary_path)
  vim.fn.jobstart({ binary_path }, { detach = true })
end

-- エディタを起動する関数
-- preset が nil の場合はデフォルトの動作（Development / UnrealEditor.exe）をします
local function run_editor(project_info, preset)
  local logger = log.get()
  
  -- エンジンルートを探す
  local engine_root, err = unl_finder.engine.find_engine_root(project_info.uproject)
  if not engine_root then 
    return logger.error("Could not find engine root: %s", tostring(err)) 
  end

  -- デフォルト値の設定
  local platform = "Win64"
  local config = "Development"

  -- presetが渡されていれば、そこから情報を取得
  if preset then
    if preset.Platform then platform = preset.Platform end
    if preset.Configuration then config = preset.Configuration end
  end

  -- 実行ファイル名の決定ロジック
  -- Development構成の場合は、サフィックスなしの "UnrealEditor.exe" が基本
  -- それ以外（Debug, DebugGameなど）の場合は "UnrealEditor-Win64-DebugGame.exe" のようになる
  local editor_exe = "UnrealEditor.exe"
  
  if config ~= "Development" then
    -- 例: UnrealEditor-Win64-DebugGame.exe
    editor_exe = string.format("UnrealEditor-%s-%s.exe", platform, config)
  end

  logger.info("Preparing to run editor with Configuration: %s", config)

  local editor_path = fs.joinpath(engine_root, "Engine", "Binaries", platform, editor_exe)
  
  if vim.fn.executable(editor_path) ~= 1 then 
    -- 失敗した場合のフォールバック提案などをログに出す
    logger.warn("Specific editor executable not found: %s", editor_path)
    logger.warn("Falling back to default 'UnrealEditor.exe'...")
    
    editor_path = fs.joinpath(engine_root, "Engine", "Binaries", platform, "UnrealEditor.exe")
    if vim.fn.executable(editor_path) ~= 1 then
        return logger.error("Default UnrealEditor.exe also not found at: %s", editor_path) 
    end
  end

  -- コマンド構築
  local cmd_to_run = { editor_path, project_info.uproject }
  logger.info("Executing: %s", table.concat(cmd_to_run, " "))
  
  -- デタッチモードで実行
  vim.fn.jobstart(cmd_to_run, { detach = true })
end

function M.start(opts)
  opts = opts or {}
  local project_info = unl_finder.project.find_from_current_buffer()
  if not project_info then
    return log.get().error("Not in an Unreal Engine project directory.")
  end

  if opts.has_bang then
    unl_picker.pick({
      kind = "ubt_run_picker",
      title = "  Select Preset to Run",
      conf = get_config(),
      items = model.get_presets(),
      logger_name = "UBT",
      preview_enabled = false,
      entry_maker = function(item)
        return {
          value = item,
          display = item.name,
          ordinal = item.name,
        }
      end,
      
      on_submit = function(selected_preset)
        if not selected_preset then return end
        
        -- 選択したプリセットを「最後に使った構成」として保存
        context.set("last_preset", selected_preset.name)
        log.get().debug("Saved last preset to context: %s", selected_preset.name)

        -- IsEditorフラグを見て、呼び出す関数を動的に決定する
        if selected_preset.IsEditor then
          -- Editorビルドの場合は、通常のエディタを起動
          run_editor(project_info, selected_preset)
        else
          -- Gameビルドの場合は、スタンドアロンバイナリを起動
          run_standalone(project_info, selected_preset)
        end
      end,
    })
  else
    -- `!`なしの場合は、これまで通りデフォルト（引数なし）で呼び出すか、
    -- コンテキストから前回の設定を読み込む
    local conf = get_config()
    local preset_to_use = nil
    
    -- 設定が有効なら、最後に使ったプリセット（buildで保存されたもの含む）を読み込む
    if conf.use_last_preset_as_default then
      local last_name = context.get("last_preset")
      if last_name then
        local found = get_preset_by_name(last_name)
        if found then
          log.get().info("Using last preset from context: %s", last_name)
          preset_to_use = found
        else
          log.get().warn("Last preset '%s' not found in current presets. Falling back to default.", last_name)
        end
      end
    end

    -- プリセットが見つかった場合はそれを使用、なければデフォルト（nil -> Development/Editor）
    if preset_to_use then
      if preset_to_use.IsEditor then
        run_editor(project_info, preset_to_use)
      else
        run_standalone(project_info, preset_to_use)
      end
    else
      -- 従来通り（Development Editor）
      run_editor(project_info, nil)
    end
  end
end

return M
