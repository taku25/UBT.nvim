-- Centralized default configuration for UNL.
local M = {
  ui = {
    picker = {
      mode = "auto",
      prefer = { "telescope", "fzf-lua", "native", "dummy" },
    },
    progress = {
      mode = "auto",
      enable = true,
      prefer = { "fidget", "dummy" },
      allow_regression = false,
    },
  },
  logging = {
    level = "info",
    echo = { level = "warn" },
    notify = { level = "error", prefix = "[UBT]" },
    file = { enable = true, max_kb = 512, rotate = 3, filename = "ubt.log" },
    perf = { enabled = false, patterns = { "^refresh" }, level = "trace" },
  },

  cache = { dirname = "UBT" },

  presets = {
    { name = "Win64DebugGame", Platform = "Win64", IsEditor = false, Configuration = "DebugGame" },
    { name = "Win64Develop", Platform = "Win64", IsEditor = false, Configuration = "Development" },
    { name = "Win64Shipping", Platform = "Win64", IsEditor = false, Configuration = "Shipping" },
    { name = "Win64DebugGameWithEditor", Platform = "Win64", IsEditor = true, Configuration = "DebugGame" },
    { name = "Win64DevelopWithEditor", Platform = "Win64", IsEditor = true, Configuration = "Development" },
  },
  preset_target = "Win64DevelopWithEditor",
  lint_type = "Default",
  engine_path = nil,
  progress_file_name = "progress.log",

  project = {
    localrc_filename = ".ubtrc",
    search_stop_at_home = true,
    follow_symlink = true,
  },
  automation = {
    -- trueにすると、UEPの軽量リフレッシュ完了後('ON_AFTER_UEP_LIGHTWEIGHT_REFRESH'イベント)に
    -- 自動で 'gen_header' コマンドを実行します。
    auto_gen_header_after_lightweight_refresh = false,

    -- 上記がtrueの場合、'gen_header'が成功した後に続けて'gen_proj'を実行します。
    -- 'gen_header'だけを自動実行したい場合は、これをfalseに設定します。
    auto_gen_project_after_gen_header_success = false,

    -- trueにすると、完全なリフレッシュ完了後('ON_AFTER_REFRESH_COMPLETED'イベント)に
    -- 自動で 'gen_proj' コマンドを実行します。
    auto_gen_project_after_refresh_completed = false,
  },
}

return M
