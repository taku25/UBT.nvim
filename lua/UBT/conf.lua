-- lua/UBT/conf.lua

local M = {}

----------------------------------------------------------------------
-- 1. Default Configuration Options
----------------------------------------------------------------------
local defaults = {
  presets = {
    { name = "Win64DebugGame", Platform = "Win64", IsEditor = false, Configuration = "DebugGame" },
    { name = "Win64Develop", Platform = "Win64", IsEditor = false, Configuration = "Development" },
    { name = "Win64Shipping", Platform = "Win64", IsEditor = false, Configuration = "Shipping" },
    { name = "Win64DebugGameWithEditor", Platform = "Win64", IsEditor = true, Configuration = "DebugGame" },
    { name = "Win64DevelopWithEditor", Platform = "Win64", IsEditor = true, Configuration = "Development" },
  },
  preset_target = "Win64DevelopWithEditor",
  lint_type = "Default",
  shell = "cmd",
  engine_path = nil,
  notify_level = "NONE",
  progress_level = "ALL",
  message_level = "ERROR",
  enable_override_fidget = true,
  enable_log_file = true,
  log_file_name = "diagnostics.log",
  progress_file_name = "progress.log",
}

M.active_config = {}
M.user_config = {}

----------------------------------------------------------------------
-- 2. Helper Functions for Configuration Merging
----------------------------------------------------------------------

local function merge_presets(base_presets, new_presets)
  if not new_presets or #new_presets == 0 then
    return base_presets
  end
  local by_name = {}
  for _, p in ipairs(base_presets) do
    by_name[p.name] = p
  end
  for _, p in ipairs(new_presets) do
    by_name[p.name] = p
  end
  local merged = {}
  for _, p in pairs(by_name) do
    table.insert(merged, p)
  end
  return merged
end

local function load_project_config(root_dir)
  local config_file_path = root_dir .. "/" .. ".ubtrc"
  if vim.fn.filereadable(config_file_path) ~= 1 then
    return {}, nil
  end
  local read_ok, file_content_lines = pcall(vim.fn.readfile, config_file_path)
  if not read_ok or not file_content_lines then
    return nil, "UBT: Failed to read .ubtrc file: " .. tostring(file_content_lines)
  end
  local json_string = table.concat(file_content_lines, "\n")
  local decode_ok, decoded_json = pcall(vim.fn.json_decode, json_string)
  if not decode_ok or type(decoded_json) ~= "table" then
    return nil, "UBT: Invalid JSON in .ubtrc file: " .. tostring(decoded_json)
  end
  return decoded_json, nil
end

----------------------------------------------------------------------
-- 3. Core Configuration Functions
----------------------------------------------------------------------

---
-- Merges multiple configuration sources and updates M.active_config
-- @param root_dir string: The current project root
function M.load_config(root_dir)
  local new_config = vim.deepcopy(defaults)
  local project_conf, err = load_project_config(root_dir)
  if err then
    logger.warn(err) -- Log the error but continue
  end

  -- Combine user's global config and project-specific config
  local configs_to_merge = { M.user_config, project_conf }

  for _, conf_table in ipairs(configs_to_merge) do
    if conf_table then
      for k, v in pairs(conf_table) do
        -- ★★★ これが、あなたの両方のプラグインを救う、最後の修正です ★★★
        if k == "presets" then
          -- For 'presets', we use a special merge function
          new_config.presets = merge_presets(new_config.presets, v)
        else
          -- For all other keys (strings, booleans, etc.), we simply overwrite
          new_config[k] = v
        end
      end
    end
  end

  M.active_config = new_config
end

---
-- The only function called by the user to initialize the plugin
function M.setup(opts)
  -- Store user config
  M.user_config = opts or {}
  M.load_config(vim.fn.getcwd())
end

-- Initialize with default or user-provided config when the module is first required
M.setup(M.user_config)

return M
