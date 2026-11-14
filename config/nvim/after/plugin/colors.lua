-- Strip opaque backgrounds so nvim inherits st's own transparency (alpha = 0.90),
-- exactly like tokyonight's `transparent = true` did before matugen was added.
local transparent_groups = {
    "Normal", "NormalNC", "NormalFloat", "FloatBorder", "FloatTitle",
    "SignColumn", "FoldColumn", "LineNr", "CursorLineNr", "EndOfBuffer",
    "MsgArea", "MsgSeparator", "VertSplit", "WinSeparator",
    "StatusLine", "StatusLineNC", "TabLine", "TabLineFill", "TabLineSel",
    "Pmenu", "NormalSB", "SignColumnSB",
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

-- Re-apply whenever a colorscheme loads (including `:colorscheme matugen` sent by theme-switch.sh)
vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("TransparentBackground", { clear = true }),
    callback = make_transparent,
})

if vim.fn.filereadable(vim.fn.expand("~/.cache/matugen/colors-nvim.lua")) == 1 then
    vim.cmd.colorscheme("matugen")
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
