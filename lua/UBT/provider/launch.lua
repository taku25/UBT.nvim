-- lua/UBT/provider/launch.lua
local run_cmd = require("UBT.cmd.run")
local model = require("UBT.model")
local unl_finder = require("UNL.finder")
local context = require("UBT.context") -- ★ 追加: 履歴アクセス用
local log = require("UBT.logger").get()

local M = {}

local function get_config()
  return require("UNL.config").get("UBT")
end

---
-- UBTの設定に基づき、実行に必要な情報(exeパス、引数)を返す
-- @param opts table { preset_name = "Win64DebugGame" } (省略可能)
-- @param on_complete function|nil 非同期コールバック
-- @return table|nil { program="...", args={...}, cwd="..." }
function M.request(opts, on_complete)
  opts = opts or {}
  log.debug("Provider 'ubt.get_launch_config' called.")

  -- 1. プロジェクト情報の取得
  local project_info = unl_finder.project.find_from_current_buffer() or unl_finder.project.find_project(vim.loop.cwd())
  if not project_info then
    log.error("Provider: Not in an Unreal Engine project.")
    if on_complete then on_complete(false, "Not in an Unreal Engine project.") end
    return nil
  end

  local preset_name = opts.preset_name

  -- 2. プリセット名の解決 (指定なし -> 履歴 -> 設定デフォルト)
  if not preset_name then
    local conf = get_config()
    
    if conf.use_last_preset_as_default then
      local last_preset = context.get("last_preset")
      if last_preset then
        log.info("Provider: Using last used preset '%s'", last_preset)
        preset_name = last_preset
      end
    end

    if not preset_name and conf.preset_target then
      log.debug("Provider: Using default preset from config '%s'", conf.preset_target)
      preset_name = conf.preset_target
    end
  end

  -- Helper to finish
  local function finish(preset)
      if not preset then
          log.warn("Provider: Preset '%s' not found.", preset_name or "Default")
          if on_complete then on_complete(false, "Preset not found") end
          return nil
      end

      -- 4. run.lua のロジックを使ってパス解決
      local launch_config = run_cmd.resolve_launch_config(project_info, preset)
      
      if launch_config then
        log.info("Provider: Resolved launch config for '%s' -> %s", preset.name, launch_config.program)
        if on_complete then on_complete(true, launch_config) end
      else
        if on_complete then on_complete(false, "Failed to resolve launch config") end
      end
      
      return launch_config
  end

  -- 3. プリセットオブジェクトの特定 (非同期)
  model.get_presets(function(presets)
      local preset = nil
      if preset_name then
        for _, p in ipairs(presets) do
          if p.name == preset_name then
            preset = p
            break
          end
        end
      else
        -- 最終手段
        preset = { IsEditor = true, Platform = "Win64", Configuration = "Development", name = "Default (Development Editor)" }
      end
      
      finish(preset)
  end)
end

return M
