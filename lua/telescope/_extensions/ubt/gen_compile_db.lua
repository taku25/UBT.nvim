-- lua/UBT/telescope/_extensions/ubt/gen_compile_db.lua

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local tconf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local ubt_api = require("UBT.api")
local ubt_picker_model = require("UBT.picker_model")

local function build(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = "UBT Build Targets",
    finder = finders.new_table({
      results = ubt_picker_model.get_presets(),
      entry_maker = function(preset)
        return {
          -- 表示されるのはプリセットの名前
          display = preset.name,
          -- アクションで使うために、プリセットのテーブル全体をvalueとして保存
          value = preset,
          ordinal = preset.name,
        }
      end,
    }),
    sorter = tconf.generic_sorter(opts),
    -- このピッカーに、ファイルプレビューは不要

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection then
          ubt_api.gen_compile_db({root_dir=vim.fn.getcwd(), label=selection.value.name})
        end
      end)
      return true
    end,
  }):find()
end

return build
