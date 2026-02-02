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

local function get_preset_by_name(name, cb)
  model.get_presets(function(presets)
    for _, p in ipairs(presets) do
      if p.name == name then return cb(p) end
    end
    cb(nil)
  end)
end

---
-- 実行構成（パス、引数、CWD）を解決して返す関数
-- @param project_info table find_projectの結果
-- @param preset table 選択されたプリセット
-- @return table|nil { program="", args={}, cwd="" }
function M.resolve_launch_config(project_info, preset)
  if not project_info or not preset then return nil end
  
  local exe_path
  local args = {}
  local cwd = project_info.root -- デフォルトはプロジェクトルート

  -- ★ OS判定を行って拡張子を決定
  local is_windows = vim.fn.has("win32") == 1
  local ext = is_windows and ".exe" or ""

  if preset.IsEditor then
    -- Editor
    local engine_root, err = unl_finder.engine.find_engine_root(project_info.uproject)
    if not engine_root then 
      log.get().error("Engine root not found: %s", tostring(err))
      return nil 
    end

    local platform = preset.Platform or "Win64"
    local config = preset.Configuration or "Development"
    local target_name = preset.TargetName or "UnrealEditor"

    -- [Fix] まずプロジェクトのBinariesフォルダ内にターゲットが存在するか確認する
    -- (Monolithic Editorターゲットや、ターゲット名がUnrealEditorでない場合への対応)
    local project_bin_dir = fs.joinpath(project_info.root, "Binaries", platform)
    local project_exe_name
    
    if config == "Development" then
        project_exe_name = target_name .. ext
    else
        project_exe_name = string.format("%s-%s-%s%s", target_name, platform, config, ext)
    end
    
    local project_exe_path = fs.joinpath(project_bin_dir, project_exe_name)

    if vim.fn.filereadable(project_exe_path) == 1 then
        -- プロジェクト側に実行ファイルがあればそれを使用
        exe_path = project_exe_path
    else
        -- なければ標準のエンジン側 UnrealEditor を使用 (Modular Build)
        local editor_exe = "UnrealEditor" .. ext
        
        if config ~= "Development" then
          editor_exe = string.format("UnrealEditor-%s-%s%s", platform, config, ext)
        end
        
        exe_path = fs.joinpath(engine_root, "Engine", "Binaries", platform, editor_exe)
    end
    
    table.insert(args, project_info.uproject) -- プロジェクトパスを引数に
  else
    -- Standalone Game
    local project_name = vim.fn.fnamemodify(project_info.uproject, ":t:r")
    local binary_name_parts = { project_name, preset.Platform }
    if preset.Configuration ~= "Development" then
      table.insert(binary_name_parts, preset.Configuration)
    end
    
    -- ★ スタンドアロンゲームも同様に拡張子を制御
    local binary_name = table.concat(binary_name_parts, "-") .. ext
    exe_path = fs.joinpath(project_info.root, "Binaries", preset.Platform, binary_name)
    
    table.insert(args, "-log") -- スタンドアロンの場合はログウィンドウを出すのが一般的
  end

  return {
    program = exe_path,
    args = args,
    cwd = cwd,
    preset_name = preset.name
  }
end

-- 内部実行用：解決したConfigを使ってjobstartする
local function execute_launch_config(config)
  if vim.fn.executable(config.program) ~= 1 then
    return log.get().error("Executable not found: %s", config.program)
  end
  
  log.get().info("Executing: %s %s", config.program, table.concat(config.args, " "))
  
  local cmd = { config.program }
  vim.list_extend(cmd, config.args)
  
  vim.fn.jobstart(cmd, { detach = true, cwd = config.cwd })
end

function M.start(opts)
  opts = opts or {}
  local project_info = unl_finder.project.find_from_current_buffer()
  if not project_info then
    return log.get().error("Not in an Unreal Engine project directory.")
  end

  if opts.has_bang then
    model.get_presets(function(presets)
        unl_picker.pick({
          kind = "ubt_run_picker",
          title = "  Select Preset to Run",
          conf = get_config(),
          items = presets,
          logger_name = "UBT",
          preview_enabled = false,
          entry_maker = function(item)
            return { value = item, display = item.name, ordinal = item.name }
          end,
          on_submit = function(selected_preset)
            if not selected_preset then return end
            context.set("last_preset", selected_preset.name)
            
            -- ★ 変更: 解決ロジックと実行ロジックを分離して呼び出す
            local launch_conf = M.resolve_launch_config(project_info, selected_preset)
            if launch_conf then execute_launch_config(launch_conf) end
          end,
        })
    end)
  else
    local conf = get_config()
    
    local function run_default(preset)
        local launch_conf = M.resolve_launch_config(project_info, preset)
        if launch_conf then execute_launch_config(launch_conf) end
    end

    if conf.use_last_preset_as_default then
      local last_name = context.get("last_preset")
      if last_name then 
          get_preset_by_name(last_name, function(p)
              if p then run_default(p) else 
                  -- Fallback if last preset not found
                  run_default({ IsEditor = true, Platform = "Win64", Configuration = "Development", name = "Default" })
              end
          end)
          return
      end
    end

    -- デフォルトプリセットを動的生成
    run_default({ IsEditor = true, Platform = "Win64", Configuration = "Development", name = "Default" })
  end
end

return M
