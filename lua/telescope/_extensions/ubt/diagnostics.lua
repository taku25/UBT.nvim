local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local sorters = require("telescope.sorters")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values
local ubt_path = require("UBT.path")
local ubt_conf = require("UBT.conf")

local function parse_log_line(line)
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
    -- vim.api.nvim_echo({{file_path, hl}}, true, {err = true})
    result.file_path = file_path
    result.col = tonumber(col)
    result.row = tonumber(row)
  end

  return result
end

local function diagnostics(opts)
  opts = opts or {}

  local log_file = ubt_path.get_progress_log_file_path()
  local lines = vim.fn.readfile(log_file)
  if not lines or vim.tbl_isempty(lines) then
    vim.notify("UBT: No diagnostics found.", vim.log.levels.INFO)
    return
  end
  
  pickers.new(opts, {
    prompt_title = "UBT Diagnostics",
    finder = finders.new_table({
      results = lines,
      entry_maker = function(line)
        local result = parse_log_line(line)
        local display_text = result.display_text
        return {
          value = result.row_message,
          display = result.display_text,
          ordinal = result.row_message,
          filepath = result.file_path,
          filename = result.file_path, 
          lnum = result.row,
          col = result.col
        }
      end,
    }),
    sorter = conf.generic_sorter(opts),
    previewer = conf.file_previewer(opts),
  }):find()
end

return diagnostics
