-- lua/UBT/api.lua (シンプルになったAPI)

local unl_finder = require("UNL.finder")
local log = require("UBT.logger")
local cmd = {
  build = require("UBT.cmd.build"),
  gencompiledb = require("UBT.cmd.gen_compile_db"),
  genproject = require("UBT.cmd.gen_proj"),
  lint = require("UBT.cmd.lint"),
  diagnostics = require("UBT.cmd.diagnostics"),
}

local M = {}

---
-- optsにroot_dirがなければ自動で設定するヘルパー関数
-- この関数を全てのAPI関数より先に定義します
local function ensure_root_dir(opts)
  opts = opts or {}
  if not opts.root_dir then
    opts.root_dir = unl_finder.project.find_project_root(vim.loop.cwd())
  end
  return opts
end

function M.build(opts)
  opts = ensure_root_dir(opts)
  if not opts.root_dir then return log.get().error("Not inside a valid Unreal project.") end
  
  cmd.build.start(opts)
end

function M.gen_compile_db(opts)
  opts = ensure_root_dir(opts)
  if not opts.root_dir then return log.get().error("Not inside a valid Unreal project.") end

  cmd.gencompiledb.start(opts)
end

function M.gen_project(opts)
  opts = ensure_root_dir(opts)
  if not opts.root_dir then return log.get().error("Not inside a valid Unreal project.") end
  cmd.genproject.start(opts)
end

function M.lint(opts)
  opts = ensure_root_dir(opts)
  if not opts.root_dir then return log.get().error("Not inside a valid Unreal project.") end
  cmd.lint.start(opts)
end

function M.diagnostics(opts)
  opts = ensure_root_dir(opts) -- root_dirを保証
  log.get().debug("API call: diagnostics")
  cmd.diagnostics.start(opts)
end
return M
