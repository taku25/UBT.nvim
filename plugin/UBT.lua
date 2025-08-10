-- Neovim plugin entry: registers user commands for UBT.nvim
if 1 ~= vim.fn.has "nvim-0.11.3" then
  vim.api.nvim_err_writeln "Telescope.nvim requires at least nvim-0.11.0. See `:h telescope.changelog-2499`"
  return
end

if vim.g.loaded_ubt == 1 then
  return
end
vim.g.loaded_ubt = 1

local gen_cmd = require("UBT.cmd.gen_compile_db")
local build_cmd = require("UBT.cmd.build")
local proj_cmd = require("UBT.cmd.gen_proj")
local log = require("UBT.log")
local conf = require("UBT.conf")

-- Register :UBT command with subcommand dispatch (e.g., :UBT GenCompileDB)
vim.api.nvim_create_user_command(
  'UBT',
  function(args)
    local sub = args.fargs[1]
    if sub == nil then
      log.notify('Usage: :UBT GenCompileDB ...', vim.log.levels.ERROR, 'UBT' )
      return
    end
    if sub:lower() == 'gencompiledb' then
      -- Pass only the remaining arguments to the actual function
      local sub_args = vim.tbl_extend('force', args, {fargs = { unpack(args.fargs, 2) }})

      log.notify(sub_args, vim.log.levels.INFO, 'UBT')
      local label = sub_args.fargs[1] or conf.default
      log.notify("Executing GenerateClanDatabase: "..label, vim.log.levels.INFO, 'UBT')
      gen_cmd.start({label=label})
    elseif sub:lower() == 'build' then
      -- Pass only the remaining arguments to the actual function
      local sub_args = vim.tbl_extend('force', args, {fargs = { unpack(args.fargs, 2) }})
      local label = sub_args.fargs[1] or conf.default
      log.notify('Executing Build: ' .. label, vim.log.levels.INFO, 'UBT')
      build_cmd.start({label = label})
    elseif sub:lower() == 'genproject' then
      log.notify('Executing GenerateProjectFiles: ', vim.log.levels.INFO, 'UBT')
      proj_cmd.start()
    else
      log.notify('Unknown subcommand: '..sub, vim.log.levels.ERROR, 'UBT')
    end
  end,
  {
    nargs = '*',
    desc = 'UBT command: UBT GenCompileDB ...',
    complete = function(_, line)
      local completions = { 'GenCompileDB', 'Build', "GenProject" }
      local split = vim.split(line, '%s+')
      if #split <= 2 then
        return vim.tbl_filter(function(cmd) return cmd:find(split[2] or '', 1, true) end, completions)
      end
      return {}
    end
  }
)

