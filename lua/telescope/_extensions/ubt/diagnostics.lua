local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local ubt_picker_model = require("UBT.model")


local function diagnostics(opts)
  opts = opts or {}

  local lines,err = ubt_picker_model.get_row_data()

  if err then
    vim.notify("UBT: No diagnostics found.", vim.log.levels.INFO)
    return
  end
  
  pickers.new(opts, {
    prompt_title = "UBT Diagnostics",
    finder = finders.new_table({
      results = lines,
      entry_maker = function(line)
        local result = ubt_picker_model.line_info(line)
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
