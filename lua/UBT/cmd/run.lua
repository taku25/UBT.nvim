-- lua/UBT/cmd/run.lua

local unl_finder = require("UNL.finder")
local log = require("UBT.logger")
local fs = require("vim.fs")
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")

local M = {}

-- スタンドアロンバイナリを起動する関数（変更なし）
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

-- ★★★ 修正箇所: エディタを起動する関数 ★★★
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

  -- ★ 実行ファイル名の決定ロジック ★
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
      conf = require("UNL.config").get("UBT"),
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
        
        -- IsEditorフラグを見て、呼び出す関数を動的に決定する
        if selected_preset.IsEditor then
          -- ★ 修正点: selected_preset を run_editor に渡す
          run_editor(project_info, selected_preset)
        else
          -- Gameビルドの場合は、スタンドアロンバイナリを起動
          run_standalone(project_info, selected_preset)
        end
      end,
    })
  else
    -- `!`なしの場合は、これまで通りデフォルト（引数なし）で呼び出す
    -- run_editor内部で nil チェックを行い、UnrealEditor.exe を起動します
    run_editor(project_info, nil)
  end
end

return M
