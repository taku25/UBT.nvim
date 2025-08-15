local fzf_lua = require("fzf-lua")
local fzf_actions = require("fzf-lua.actions") 
local model = require("UBT.picker_model")
local api = require("UBT.api")
local path = require("UBT.path")

local M={}

M.exec = function()
  fzf_lua.fzf_exec(
    function(fzf_cb)
      local log_file = path.get_progress_log_file_path()
      if vim.fn.filereadable(log_file) == 0 then
        writer:warn("Diagnostics log file not found.")
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
      -- プレビュー機能を追加するとさらに強力になります（オプション）
      -- previewer = "bat", -- or "cat"
      prompt = " UBT Diagnostics>",
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
