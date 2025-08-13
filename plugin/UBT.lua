-- ubt.lua (リファクタリング後)

if 1 ~= vim.fn.has "nvim-0.11.3" then
  vim.api.nvim_err_writeln "UBT.nvim at least nvim-0.11.3"
  return 
end
if vim.g.loaded_ubt == 1 then
  return
end
vim.g.loaded_ubt = 1

-- 各コマンドモジュールをrequire
--.
local cmd = require("UBT.cmd")
local logger = require("UBT.logger")
local conf = require("UBT.conf")


-- =================================================================
--  コマンド定義テーブル
-- =================================================================
-- 各サブコマンドの動作をここで一元管理する
local subcommands = {
  -- :UBT GenCompileDB [label]
  gencompiledb = {
    handler = cmd.gen_compile_db,
    desc = "Generate compile database.",
    -- このコマンドが取る引数の定義
    args = {
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },

  -- :UBT Build [label]
  build = {
    handler = cmd.build,
    desc = "Build the project.",
    args = {
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },

  -- :UBT GenProject
  genproject = {
    handler = cmd.gen_proj,
    desc = "Generate project files.",
    args = {}, -- このコマンドは追加の引数を取らない
  },

  -- :UBT Lint [lintType] [targetType]
  lint = {
    handler = cmd.lint,
    desc = "Run static analyzer.",
    args = {
      { name = "lintType", default = function() return conf.active_config.lint_type end },
      { name = "label", default = function() return conf.active_config.preset_target end },
    },
  },
}
-- =================================================================


vim.api.nvim_create_user_command(
  'UBT',
  function(args)
    local fargs = args.fargs
    local sub_name = fargs[1]

    if not sub_name then
      logger.write("Usage: :UBT <subcommand> ...", vim.log.levels.ERROR)
      -- ここで利用可能なサブコマンド一覧を表示するのも親切
      return
    end

    -- 入力されたサブコマンド名（小文字）で、定義テーブルを検索
    local command_def = subcommands[sub_name:lower()]
    if not command_def then
      logger.write("Unknown subcommand: " .. sub_name, vim.log.levels.ERROR, 'UBT')
      return
    end


  
    local root_dir = vim.fn.getcwd()
    conf.load_config(root_dir)

    -- === 引数解析ロジック ===
    local opts = {
      root_dir = root_dir,
    }
    local user_args = { unpack(fargs, 2) } -- ユーザーが入力した引数 (サブコマンド名を除く)

    -- 定義された各引数について、ユーザーからの入力値またはデフォルト値を取得
    for i, arg_def in ipairs(command_def.args) do
      local value = user_args[i] or arg_def.default()
      opts[arg_def.name] = value
    end

    logger.write("Executing: " .. sub_name .. " with opts: " .. vim.inspect(opts), vim.log.levels.INFO, 'UBT')

    -- 対応するハンドラの .start() 関数を呼び出す
    local handle, error = command_def.handler.start(opts)
    if error ~= nil then
      logger.write(error, vim.log.levels.ERROR, 'UBT')
    end
  end,
  {
    nargs = '*',
    desc = 'UBT command launcher. Use :UBT <subcommand>',
    -- 補完機能も、定義テーブルを使って自動的に生成する
    complete = function(_, line)
      local split = vim.split(line, "%s+")
      if #split <= 2 then
        local available_cmds = vim.tbl_keys(subcommands)
        return vim.tbl_filter(function(cmd)
          return vim.startswith(cmd, split[2] or "")
        end, available_cmds)
      end
      -- TODO: 将来的には、各コマンドの引数の補完もここに追加できる
      return {}
    end,
  }
)
