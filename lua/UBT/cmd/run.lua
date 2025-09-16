-- lua/UBT/cmd/run.lua (命名規則対応版)

local unl_finder = require("UNL.finder")
local log = require("UBT.logger")
local fs = require("vim.fs")
local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")

local M = {}

-- スタンドアロンバイナリを起動する関数
local function run_standalone(project_info, preset)
  local logger = log.get()
  logger.info("Running standalone build with preset: %s", preset.name)
  
  local project_name = vim.fn.fnamemodify(project_info.uproject, ":t:r")
  
  -- ▼▼▼ 修正箇所: Developmentビルドの命名規則に対応 ▼▼▼
  local binary_name_parts = {
    project_name,
    preset.Platform,
  }
  
  -- 'Development' ではない場合のみ、コンフィグレーション名をファイル名に追加
  if preset.Configuration ~= "Development" then
    table.insert(binary_name_parts, preset.Configuration)
  end

  local binary_name = table.concat(binary_name_parts, "-") .. ".exe"
  -- ▲▲▲ ここまで ▲▲▲
  
  local binary_path = fs.joinpath(project_info.root, "Binaries", preset.Platform, binary_name)

  if vim.fn.executable(binary_path) ~= 1 then
    return logger.error("Standalone binary not found or not executable: %s", binary_path)
  end
  
  logger.info("Executing: %s", binary_path)
  vim.fn.jobstart({ binary_path }, { detach = true })
end

-- 通常のエディタを起動する関数 (変更なし)
local function run_editor(project_info)
  local logger = log.get()
  logger.info("Running editor...")
  local engine_root, err = unl_finder.engine.find_engine_root(project_info.uproject)
  if not engine_root then return logger.error("Could not find engine root: %s", tostring(err)) end
  local platform = "Win64"
  local editor_exe = "UnrealEditor.exe"
  local editor_path = fs.joinpath(engine_root, "Engine", "Binaries", platform, editor_exe)
  if vim.fn.executable(editor_path) ~= 1 then return logger.error("UnrealEditor.exe not found or not executable: %s", editor_path) end
  local cmd_to_run = { editor_path, project_info.uproject }
  logger.info("Executing: %s", table.concat(cmd_to_run, " "))
  vim.fn.jobstart(cmd_to_run, { detach = true })
end

-- M.start関数 (変更なし)
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
      
      -- ▼▼▼ ここからが修正箇所 ▼▼▼
      on_submit = function(selected_preset)
        if not selected_preset then return end
        
        -- IsEditorフラグを見て、呼び出す関数を動的に決定する
        if selected_preset.IsEditor then
          -- Editorビルドの場合は、通常のエディタを起動
          run_editor(project_info)
        else
          -- Gameビルドの場合は、スタンドアロンバイナリを起動
          run_standalone(project_info, selected_preset)
        end
      end,
      -- ▲▲▲ ここまで ▲▲▲
    })
  else
    -- `!`なしの場合は、これまで通り通常のエディタを起動
    run_editor(project_info)
  end
end

return M
