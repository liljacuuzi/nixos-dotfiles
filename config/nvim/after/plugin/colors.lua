-- Strip opaque backgrounds so nvim inherits st's own transparency (alpha = 0.90),
-- exactly like tokyonight's `transparent = true` did before matugen was added.
local transparent_groups = {
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle", "FloatFooter",
    "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "EndOfBuffer",
    "MsgArea", "MsgSeparator", "VertSplit", "WinSeparator",
    "StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "TabLineSel",
    "Pmenu", "PmenuBorder", "NormalSB", "SignColumnSB",
    "TelescopeNormal", "TelescopeBorder", "TelescopePromptNormal",
    "TelescopePromptBorder", "TelescopeResultsNormal", "TelescopeResultsBorder",
    "TelescopePreviewNormal", "TelescopePreviewBorder",
    "WinBar", "WinBarNC",
}

local function make_transparent()
    for _, group in ipairs(transparent_groups) do
        local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = group, link = false })
        if ok then
            hl.bg = nil
            hl.ctermbg = nil
            vim.api.nvim_set_hl(0, group, hl)
        end
    end
end

local function apply_terminal_colors()
    local term_path = vim.fn.expand("~/.cache/matugen/colors-nvim-term.lua")
    local ok, term = pcall(dofile, term_path)
    if ok and type(term) == "table" then
        for i = 0, 15 do
            local col = term["color" .. i]
            if type(col) == "string" then
                vim.g["terminal_color_" .. i] = col
            end
        end
    end
end

-- Re-apply whenever a colorscheme loads (including SIGUSR1 reload via matugen.nvim)
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true }),
    callback = function()
        make_transparent()
        apply_terminal_colors()
    end,
})

local palette_path = vim.fn.expand("~/.cache/matugen/nvim-colors.json")
local ok_matugen, matugen = pcall(require, "matugen")
if ok_matugen and vim.fn.filereadable(palette_path) == 1 then
    matugen.setup({
        palette_path = palette_path,
        load_theme = false,
    })
    -- Synchronous load so ColorScheme autocmds and lualine setup see the active theme immediately
    matugen.load_theme(true)
else
    local status, tokyonight = pcall(require, "tokyonight")
    if not status then return end

    tokyonight.setup({
        style = "night",
        transparent = true, -- Handles background stripping automatically
    })

    vim.cmd.colorscheme("tokyonight-night")
end

make_transparent()
apply_terminal_colors()
