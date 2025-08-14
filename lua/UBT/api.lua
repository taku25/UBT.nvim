--- UBT.nvim: Public Lua API.
-- These functions are the stable, intended way to interact with UBT.nvim
-- programmatically from your own configurations or other plugins.
local M = {}

-- Require the internal engine room.
local internal = require("UBT.internal")

--- Builds the project using a specified target.
-- @param opts table|nil: Options table, e.g., { label = "Win64Debug", root_dir = "/path/to/project" }.
-- If `label` is omitted, the configured default will be used.
function M.build(opts)
  internal.execute_command("build", opts)
end

--- Generates compile_commands.json for a specified target.
-- @param opts table|nil: Options table, e.g., { label = "Win64Debug" }.
function M.gen_compile_db(opts)
  internal.execute_command("gencompiledb", opts)
end

--- Generates project files (e.g., for Visual Studio).
-- @param opts table|nil: Options table, e.g., { root_dir = "/path/to/project" }.
function M.gen_project(opts)
  internal.execute_command("genproject", opts)
end

--- Runs the static analyzer (linter).
-- @param opts table|nil: Options table, e.g., { lintType = "Clang", label = "Win64Debug" }.
function M.lint(opts)
  internal.execute_command("lint", opts)
end


--- Searches upwards from a given path to find the project root directory.
-- The project root is defined as the directory containing a .uproject file.
-- @param start_path string: The file or directory path to start searching from.
-- @return string|nil: The absolute path to the project root directory if found.
-- @return string|nil: An error message if not found or on failure.
function M.find_project_root(start_path)
  -- ★★★ 実際の処理は、専門家であるpath.luaに、そのまま委譲する ★★★
  return path.find_project_root(start_path)
end

return M
