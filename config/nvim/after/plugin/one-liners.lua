require("lualine").setup({ options = { theme = "auto" } })
require("nvim-highlight-colors").setup({})

-- lualine.setup() overwrites lualine_* highlights with theme = "auto";
-- re-apply matugen.nvim's Material You lualine highlights silently via :colorscheme.
if vim.g.colors_name == "matugen" then
    vim.cmd.colorscheme("matugen")
end
