local fzf_lua = require("fzf-lua")
local fzf_actions = require("fzf-lua.actions") 
local model = require("UBT.model")
local path = require("UBT.path")
local builtin = require("fzf-lua.previewer.builtin")


local M={}

-- Inherit from the "buffer_or_file" previewer
local diagnostics_Previewer = builtin.buffer_or_file:extend()

function diagnostics_Previewer:new(o, opts, fzf_win)
  diagnostics_Previewer.super.new(self, o, opts, fzf_win)
  setmetatable(self, diagnostics_Previewer)
  return self
end
--
function diagnostics_Previewer:parse_entry(entry_str)
    local line_info = model.line_info(entry_str)
    if not line_info.file_path then
      return {}
    end
      return {
        path = line_info.file_path,--path,
        line = tonumber(line_info.row) or 1,
        col = tonumber(line_info.col) or 1,
     }
end

M.exec = function()
  fzf_lua.fzf_exec(
    function(fzf_cb)
      local log_file = path.get_progress_log_file_path()
      if vim.fn.filereadable(log_file) == 0 then
        fzf_cb()
        return
      end

      coroutine.wrap(function()
        local co = coroutine.running()
        for line in io.lines(log_file) do

          fzf_cb(line, function() coroutine.resume(co) end)
          coroutine.yield()
        end
        fzf_cb()
      end)()
    end,
    {

      prompt = "  UBT Diagnostics>",
      previewer = diagnostics_Previewer,
      actions = {
        ["default"] = function(selected, opts)
          local line = selected[1]
          if not line then return end

          local line_info = model.line_info(line)
          if line_info.file_path then

           local location_string = string.format(
                "%s:%d:%d",
                line_info.file_path,
                line_info.row,
                line_info.col
              )
            fzf_actions.file_edit({ location_string }, opts)
          end
        end,
      }
    }
  )
end

return M
