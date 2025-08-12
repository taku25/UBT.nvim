-- UBT.nvim: build config presets and user config merge
local M = {}

-- 標準プリセット
M.presets = {
  {
    name = "Win64Debug",
    Platform = "Win64",
    IsEditor = false,
    Configuration = "Debug",
  },
  {
    name = "Win64DebugGame",
    Platform = "Win64",
    IsEditor = false,
    Configuration = "DebugGame",
  },
  {
    name = "Win64Develop",
    Platform = "Win64",
    IsEditor = false,
    Configuration = "Development",
  },
  {
    name = "Win64Shipping",
    Platform = "Win64",
    IsEditor = false,
    Configuration = "Shipping",
  },
  {
    name = "Win64Test",
    Platform = "Win64",
    IsEditor = false,
    Configuration = "Test",
  },
  {
    name = "Win64DebugWithEditor",
    Platform = "Win64",
    IsEditor = true,
    Configuration = "Debug",
  },
  {
    name = "Win64DebugGameWithEditor",
    Platform = "Win64",
    IsEditor = true,
    Configuration = "DebugGame",
  },
  {
    name = "Win64DevelopWithEditor",
    Platform = "Win64",
    IsEditor = true,
    Configuration = "Development",
  },
}

-- default label
M.preset_target = "Win64DevelopWithEditor"
-- default lintertype
M.lint_type = "Default"
-- default shell
M.shell = "cmd"
-- enable or dislable notify
M.notify = false 
-- override fidget setting
M.enable_override_fidget = true

-- ユーザー設定をマージするsetup
function M.setup(user_conf)
  user_conf = user_conf or {}
  -- preset追加・上書き
  if user_conf.presets then
    local by_name = {}
    for _,p in ipairs(M.presets) do by_name[p.name] = p end
    for _,p in ipairs(user_conf.presets) do by_name[p.name] = p end
    local merged = {}
    for _,p in pairs(by_name) do table.insert(merged, p) end
    M.presets = merged
  end
  -- デフォルト名
  if user_conf.default then M.default = user_conf.default end
  -- shell
  if user_conf.shell then M.shell = user_conf.shell end
end

return M

