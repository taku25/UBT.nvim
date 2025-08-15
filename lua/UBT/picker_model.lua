local M = {}

local ubt_conf = require("UBT.conf")
local ubt_path = require("UBT.path")


M.line_info = function(line)
  local clean_line = line:gsub("^%[.-%]%s*", "")

  local level, rest = clean_line:match("^%[(%u+)%]%s+(.*)")

  local file_path, row, col = nil, nil, nil

  -- ERROR / WARN は常に対象
  if level == "ERROR" or level == "WARN" then
    file_path, row, col = rest:match("^(.-)%((%d+),(%d+)%)")
  else
    --logには存在しないので1,1でうめる
    file_path = clean_line:match("^%[INFO%]%s+Log file:%s+(.+)$")
    row = 1
    col = 1
  end

  local result = {
    display_text = clean_line,
    row_message = rest,
    file_path = nil,
    row = 0,
    col = 0,
  }

  if file_path then
    result.file_path = file_path
    result.row = tonumber(row)
    result.col = tonumber(col)
  end

  return result
end

M.get_row_data = function()
  ubt_conf.load_config(vim.fn.getcwd())
  local log_file = ubt_path.get_progress_log_file_path()
  local lines = vim.fn.readfile(log_file)
  if not lines or vim.tbl_isempty(lines) then
    return nil, "UBT: No diagnostics found"
  end
  return lines,nil
end

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

function M.get_presets()
  ubt_conf.load_config(vim.fn.getcwd())
  return ubt_conf.active_config.presets
end

function M.get_presets_names()
  local preset_names = {}
  for _, preset in ipairs(M.get_presets()) do
    -- 正しい構文: table.insert(テーブル名, 追加する値)
    table.insert(preset_names, preset.name)
  end
  return preset_names
end

return M
