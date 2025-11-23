-- lua/UBT/provider/launch.lua
local run_cmd = require("UBT.cmd.run")
local model = require("UBT.model")
local unl_finder = require("UNL.finder")
local log = require("UBT.logger").get()

local M = {}

---
-- UBTの設定に基づき、実行に必要な情報(exeパス、引数)を返す
-- @param opts table { preset_name = "Win64DebugGame" } (省略可能)
-- @return table|nil { program="...", args={...}, cwd="..." }
function M.request(opts)
  opts = opts or {}
  log.debug("Provider 'ubt.get_launch_config' called.")

  -- 1. プロジェクト情報の取得
  local project_info = unl_finder.project.find_from_current_buffer() or unl_finder.project.find_project(vim.loop.cwd())
  if not project_info then
    log.error("Provider: Not in an Unreal Engine project.")
    return nil
  end

  -- 2. プリセットの特定
  local preset = nil
  if opts.preset_name then
    -- 指定されたプリセットを探す
    local presets = model.get_presets()
    for _, p in ipairs(presets) do
      if p.name == opts.preset_name then
        preset = p
        break
      end
    end
    if not preset then
      log.warn("Provider: Preset '%s' not found.", opts.preset_name)
      return nil
    end
  else
    -- 指定がなければ、run.lua のロジックと同様に「最後に使ったもの」か「デフォルト」を取得したいが、
    -- ここではシンプルに「指定がなければ失敗」または「最初のものを返す」などポリシーを決める必要がある。
    -- 今回は安全のため、preset_name必須とするか、デフォルトをDevelopment Editorにする。
    preset = { IsEditor = true, Platform = "Win64", Configuration = "Development", name = "Default (Development Editor)" }
  end

  -- 3. run.lua のロジックを使ってパス解決
  local launch_config = run_cmd.resolve_launch_config(project_info, preset)
  
  if launch_config then
    log.info("Provider: Resolved launch config for '%s' -> %s", preset.name, launch_config.program)
  end

  return launch_config
end

return M
