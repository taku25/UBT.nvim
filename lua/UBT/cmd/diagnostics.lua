-- lua/UBT/cmd/diagnostics.lua

local unl_picker = require("UNL.backend.picker")
local ubt_model = require("UBT.model")
local ubt_logger = require("UBT.logger")

local M = {}

---
-- entry_maker: ログ1行を「標準ピッカーアイテム形式」に変換する
-- @param line string ログファイルから読み込んだ1行
-- @return table 標準ピッカーアイテム
local function entry_maker(line)
  local info = ubt_model.line_info(line)
  return {
    -- on_submitには、ファイルを開くのに十分な情報を持つテーブルを渡す
    -- value = {
    --   filename = info.file_path,
    --   lnum = info.row,
    --   col = info.col,
    -- },
    value = info.row_message,
    display = info.display_text,
    ordinal = info.row_message,
    
    -- TelescopeのプレビューやQuickfixのために詳細情報を渡す
    filepath = info.file_path,
    filename = info.file_path,
    lnum = info.row,
    col = info.col,
    text = info.row_message,
  }
end

---
-- on_submit: ユーザーがアイテムを選択したときのコールバック
-- @param selection table entry_makerが返したテーブルの value フィールド
local function on_submit(selection)
  if not (selection and selection.filename) then
    return
  end
  -- ファイルを開いて指定の行/桁にジャンプ
  vim.cmd.edit(vim.fn.fnameescape(selection.filename))
  vim.api.nvim_win_set_cursor(0, { selection.lnum or 1, selection.col and (selection.col - 1) or 0 })
end

---
-- 診断ピッカーを開始する
function M.start()
  local lines, err = ubt_model.get_row_data()
  if err then
    return ubt_logger.get().warn(err)
  end

  unl_picker.pick({
    -- UEP側の設定を使いたいので、confを渡す
    conf = require("UNL.config").get("UBT"),
    logger_name = "UBT",
    
    kind = "file_location", -- quickfixが使えるようにkindを指定
    title = "  UBT Diagnostics",
    items = lines, -- データソースは生の文字列のテーブル

    entry_maker = entry_maker, -- ★★★ ここが新しいAPI ★★★
    on_submit = on_submit,
    
    -- (オプション) Telescopeにプレビューを有効にするよう伝える
    preview_enabled = true,
  })
end

return M
