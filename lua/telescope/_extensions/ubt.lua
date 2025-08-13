local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("option requires nvim-telescope/telescope.nvim")
end

return telescope.register_extension({
  exports =
  {
    diagnostics = require("telescope._extensions.ubt.diagnostics"),
    build = require("telescope._extensions.ubt.build"),
    gencompiledb = require("telescope._extensions.ubt.gen_compile_db"),
  },
})

