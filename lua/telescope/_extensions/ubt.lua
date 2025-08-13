local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error("option requires nvim-telescope/telescope.nvim")
end

local diagnostics = require("telescope._extensions.ubt.diagnostics")

return telescope.register_extension({
  exports =
  {
    diagnostics = diagnostics,
  },
})

