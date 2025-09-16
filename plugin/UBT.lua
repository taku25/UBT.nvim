-- plugin/ubt.lua (デバッグ最終版)

if vim.g.loaded_ubt then
  return
end
vim.g.loaded_ubt = true

-- requireを安全に実行し、失敗したらエラーを明確に表示するヘルパー
local function safe_require(name)
  local ok, mod = pcall(require, name)
  if not ok then
    -- pcallが失敗した場合、`mod`にはエラーメッセージが入っている
    print("UBT.nvim: !!! FATAL ERROR! require('" .. name .. "') failed!")
    -- vim.api.nvim_err_writeln("UBT.nvim FATAL ERROR while requiring '" .. name .. "':")
    -- vim.api.nvim_err_writeln(tostring(mod))
    return nil
  end
  return mod
end

local builder = safe_require("UNL.command.builder")
if not builder then return end
local ubt_api = safe_require("UBT.api")
if not ubt_api then return end
local log = safe_require("UBT.logger")
if not log then return end

local function get_config()
  return require("UNL.config").get("UBT")
end

builder.create({
  plugin_name = "UBT",
  cmd_name = "UBT",
  desc = "UBT: Unreal Build Tool commands",
  subcommands = {
    ["build"] = {
      handler = function(opts) ubt_api.build(opts) end,
      desc = "Build a target. Use 'build!' to open a UI picker.",
      bang = true,
      args = {
        { name = "label", required = false, default = function() return get_config().preset_target end },
      },
    },
    ["gencompiledb"] = {
      handler = function(opts) ubt_api.gen_compile_db(opts) end,
      desc = "Generate compile_commands.json. Use 'gencompiledb!' to open a UI picker.",
      bang = true,
      args = {
        { name = "label", required = false, default = function() return get_config().preset_target end },
      },
    },
    ["genheader"] = {
      handler = function(opts) ubt_api.gen_header(opts) end,
      desc = "Generate headers using Unreal Header Tool. Use 'genheader!' to open a UI picker.",
      bang = true,
      args = {
        { name = "label", required = false, default = function() return get_config().preset_target end },
        { name = "module_name", required = false },
      },
    },
    ["genproject"] = {
      handler = function(opts) ubt_api.gen_project(opts) end,
      desc = "Generate project files.",
      args = {},
    },
    ["lint"] = {
      handler = function(opts) ubt_api.lint(opts) end,
      desc = "Run static analyzer for a target.",
      args = {
        { name = "label", required = false, default = function() return get_config().preset_target end },
        { name = "lintType", required = false, default = function() return get_config().lint_type end },
      },
    },
    ["diagnostics"] = {
      handler = function(opts) ubt_api.diagnostics(opts) end,
      desc = "Show build diagnostics from the last run.",
      args = {}, -- 引数は取らない
    },
    ["run"] = {
      handler = function(opts) ubt_api.run(opts) end,
      desc = "Run the project. Default: Editor (-game). Use --standalone to run the binary.",
      bang = true,
      args = {
        { name = "standalone_flag", required = false }, -- "--standalone" を受け取る
      },
    },
  },
})
