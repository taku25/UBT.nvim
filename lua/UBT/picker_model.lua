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
    file_path = clean_line:match("^%[INFO%]%s+Log file:%s+(.+)$")
    row = 0
    col = 0
  end

  local result = {
    display_text = clean_line,
    row_message = rest,
    file_path = nil,
    col = 0,
    row = 0,
  }

  if file_path then
    result.file_path = file_path
    result.col = tonumber(col)
    result.row = tonumber(row)
  end

  return result
end

M.get_diagnostics = function()
  ubt_conf.load_config(vim.fn.getcwd())
  local log_file = ubt_path.get_progress_log_file_path()
  local lines = vim.fn.readfile(log_file)
  if not lines or vim.tbl_isempty(lines) then
    return nil, "UBT: No diagnostics found"
  end
  return lines,nil
end

function M.get_presets()
  ubt_conf.load_config(vim.fn.getcwd())
  return ubt_conf.active_config.presets
end

return M
