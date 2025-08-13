-- lua/UBT/telescope/_extensions/ubt/gen_compile_db.lua

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local tconf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local ubt_conf = require("UBT.conf")
local gen_compile_cmd = require("UBT.cmd.gen_compile_db")

local function build(opts)
  opts = opts or {}

  ubt_conf.load_config(vim.fn.getcwd())
  
  pickers.new(opts, {
    prompt_title = "UBT Build Targets",
    finder = finders.new_table({
      results = ubt_conf.active_config.presets,
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
          gen_compile_cmd.start({
            root_dir = vim.fn.getcwd(),
            label = selection.value.name,
          })
        end
      end)
      return true
    end,
  }):find()
end

return build
