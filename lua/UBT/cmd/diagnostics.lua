-- lua/UBT/cmd/diagnostics.lua

local unl_picker = require("UNL.backend.picker")
local model = require("UBT.model")
local log = require("UBT.logger")

local M = {}

function M.start(opts)
  -- 1. modelから解析済みの診断データを取得
  local diagnostics_data, err = model.get_diagnostics()
  if err then
    return log.get().warn(err)
  end

  -- 2. Pickerで表示するために、データを{ label, value }形式に変換
  local picker_items = {}
  for _, data in ipairs(diagnostics_data) do
    table.insert(picker_items, {
      label = data.display_text, -- 表示されるテキスト
      value = data, -- on_submitで受け取る、全ての情報が入ったテーブル
    })
  end

  -- 3. UNL.pickerを呼び出す
  unl_picker.pick({
    kind = "ubt_diagnostics",
    title = "UBT Diagnostics",
    conf = require("UNL.config").get("UBT"),
    items = picker_items,
    preview_enabled = true, -- ファイルプレビューを有効にする
    
    -- プレビューのために、Telescopeにファイルパスを教える
    -- valueテーブル内のどのキーがファイルパスであるかを指定
    format = function(entry)
      return {
        filename = entry.value.file_path,
        lnum = entry.value.row,
        col = entry.value.col,
      }
    end,

    on_submit = function(selected)
      if not (selected and selected.file_path) then
        return
      end
      -- 選択されたら、そのファイルと行にジャンプ
      vim.cmd(string.format("edit +%d %s", selected.row or 1, vim.fn.fnameescape(selected.file_path)))
      if selected.col then
        vim.api.nvim_win_set_cursor(0, { selected.row, selected.col - 1 })
      end
    end,
  })
end

return M
