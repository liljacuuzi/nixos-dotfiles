-- Matugen Base16 colorscheme for Neovim
-- Loads dynamically generated ~/.cache/matugen/colors-nvim.lua

vim.cmd("hi clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "matugen"

local fallback = {
    base00 = "#1a1b26",
    base01 = "#24283b",
    base02 = "#292e42",
    base03 = "#565f89",
    base04 = "#737aa2",
    base05 = "#c0caf5",
    base06 = "#d5ddf7",
    base07 = "#f8f9fc",
    base08 = "#f7768e",
    base09 = "#ff9e64",
    base0A = "#e0af68",
    base0B = "#9ece6a",
    base0C = "#7dcfff",
    base0D = "#7aa2f7",
    base0E = "#bb9af7",
    base0F = "#db4b4b",
}

local palette_path = vim.fn.expand("~/.cache/matugen/colors-nvim.lua")
local ok, loaded = pcall(dofile, palette_path)
local p = (ok and type(loaded) == "table") and loaded or fallback
for k, v in pairs(fallback) do
    if type(p[k]) ~= "string" then
        p[k] = v
    end
end

local function hi(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
end

-- Core UI
hi("Normal", { fg = p.base05, bg = p.base00 })
hi("NormalNC", { fg = p.base05, bg = p.base00 })
hi("NormalFloat", { fg = p.base05, bg = p.base01 })
hi("FloatBorder", { fg = p.base0D, bg = p.base01 })
hi("FloatTitle", { fg = p.base0D, bg = p.base01, bold = true })
hi("Cursor", { fg = p.base00, bg = p.base05 })
hi("CursorLine", { bg = p.base01 })
hi("CursorColumn", { bg = p.base01 })
hi("ColorColumn", { bg = p.base01 })
hi("LineNr", { fg = p.base03 })
hi("CursorLineNr", { fg = p.base0A, bold = true })
hi("SignColumn", { fg = p.base03, bg = p.base00 })
hi("Folded", { fg = p.base03, bg = p.base01 })
hi("FoldColumn", { fg = p.base0C, bg = p.base00 })
hi("StatusLine", { fg = p.base05, bg = p.base02 })
hi("StatusLineNC", { fg = p.base03, bg = p.base01 })
hi("TabLine", { fg = p.base03, bg = p.base01 })
hi("TabLineFill", { fg = p.base03, bg = p.base01 })
hi("TabLineSel", { fg = p.base00, bg = p.base0D, bold = true })
hi("WinBar", { fg = p.base05, bg = p.base00, bold = true })
hi("WinBarNC", { fg = p.base04, bg = p.base00 })
hi("VertSplit", { fg = p.base02 })
hi("WinSeparator", { fg = p.base02 })
hi("Pmenu", { fg = p.base05, bg = p.base01 })
hi("PmenuSel", { fg = p.base01, bg = p.base0D, bold = true })
hi("PmenuSbar", { bg = p.base02 })
hi("PmenuThumb", { bg = p.base04 })
hi("Search", { fg = p.base01, bg = p.base0A })
hi("IncSearch", { fg = p.base01, bg = p.base09 })
hi("CurSearch", { fg = p.base01, bg = p.base09, bold = true })
hi("Visual", { bg = p.base02 })
hi("VisualNOS", { fg = p.base08 })
hi("MatchParen", { fg = p.base09, bg = p.base02, bold = true })
hi("Directory", { fg = p.base0D })
hi("Title", { fg = p.base0D, bold = true })
hi("NonText", { fg = p.base03 })
hi("SpecialKey", { fg = p.base03 })
hi("EndOfBuffer", { fg = p.base03 })
hi("Conceal", { fg = p.base0D })
hi("ErrorMsg", { fg = p.base08, bold = true })
hi("WarningMsg", { fg = p.base09 })
hi("MoreMsg", { fg = p.base0B })
hi("ModeMsg", { fg = p.base0B, bold = true })
hi("Question", { fg = p.base0D })
hi("QuickFixLine", { bg = p.base01 })
hi("Substitute", { fg = p.base01, bg = p.base0A })
hi("WildMenu", { fg = p.base08, bg = p.base0A })

-- Diff
hi("DiffAdd", { fg = p.base0B, bg = p.base01 })
hi("DiffChange", { fg = p.base03, bg = p.base01 })
hi("DiffDelete", { fg = p.base08, bg = p.base01 })
hi("DiffText", { fg = p.base0D, bg = p.base02 })
hi("Added", { fg = p.base0B })
hi("Changed", { fg = p.base0D })
hi("Removed", { fg = p.base08 })

-- Syntax
hi("Comment", { fg = p.base03, italic = true })
hi("Constant", { fg = p.base09 })
hi("String", { fg = p.base0B })
hi("Character", { fg = p.base08 })
hi("Number", { fg = p.base09 })
hi("Boolean", { fg = p.base09 })
hi("Float", { fg = p.base09 })
hi("Identifier", { fg = p.base08 })
hi("Function", { fg = p.base0D })
hi("Statement", { fg = p.base08 })
hi("Conditional", { fg = p.base0E })
hi("Repeat", { fg = p.base0A })
hi("Label", { fg = p.base0A })
hi("Operator", { fg = p.base05 })
hi("Keyword", { fg = p.base0E })
hi("Exception", { fg = p.base08 })
hi("PreProc", { fg = p.base0A })
hi("Include", { fg = p.base0D })
hi("Define", { fg = p.base0E })
hi("Macro", { fg = p.base08 })
hi("PreCondit", { fg = p.base0A })
hi("Type", { fg = p.base0A })
hi("StorageClass", { fg = p.base0A })
hi("Structure", { fg = p.base0E })
hi("Typedef", { fg = p.base0A })
hi("Special", { fg = p.base0C })
hi("SpecialChar", { fg = p.base0F })
hi("Tag", { fg = p.base0A })
hi("Delimiter", { fg = p.base0F })
hi("SpecialComment", { fg = p.base0C })
hi("Debug", { fg = p.base08 })
hi("Underlined", { fg = p.base0C, underline = true })
hi("Error", { fg = p.base00, bg = p.base08 })
hi("Todo", { fg = p.base0A, bg = p.base01, bold = true })

-- Diagnostics & LSP
hi("DiagnosticError", { fg = p.base08 })
hi("DiagnosticWarn", { fg = p.base0A })
hi("DiagnosticInfo", { fg = p.base0D })
hi("DiagnosticHint", { fg = p.base0C })
hi("DiagnosticOk", { fg = p.base0B })
hi("DiagnosticUnderlineError", { undercurl = true, sp = p.base08 })
hi("DiagnosticUnderlineWarn", { undercurl = true, sp = p.base0A })
hi("DiagnosticUnderlineInfo", { undercurl = true, sp = p.base0D })
hi("DiagnosticUnderlineHint", { undercurl = true, sp = p.base0C })

-- Treesitter captures
local ts_links = {
    ["@comment"] = "Comment",
    ["@constant"] = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@string"] = "String",
    ["@string.escape"] = "SpecialChar",
    ["@character"] = "Character",
    ["@number"] = "Number",
    ["@boolean"] = "Boolean",
    ["@float"] = "Float",
    ["@function"] = "Function",
    ["@function.builtin"] = "Special",
    ["@function.method"] = "Function",
    ["@constructor"] = "Type",
    ["@keyword"] = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.return"] = "Keyword",
    ["@keyword.conditional"] = "Conditional",
    ["@keyword.repeat"] = "Repeat",
    ["@keyword.operator"] = "Operator",
    ["@operator"] = "Operator",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@variable"] = "Identifier",
    ["@variable.builtin"] = "Constant",
    ["@variable.parameter"] = "Identifier",
    ["@variable.member"] = "Identifier",
    ["@property"] = "Identifier",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "Delimiter",
    ["@punctuation.special"] = "Special",
    ["@tag"] = "Tag",
    ["@tag.attribute"] = "Identifier",
    ["@tag.delimiter"] = "Delimiter",
    ["@markup.heading"] = "Title",
    ["@markup.link"] = "Underlined",
    ["@markup.raw"] = "String",
}
for capture, target in pairs(ts_links) do
    hi(capture, { link = target })
end
hi("@variable", { fg = p.base05 })

-- Telescope & Completion
hi("TelescopeNormal", { fg = p.base05, bg = p.base00 })
hi("TelescopeBorder", { fg = p.base0D, bg = p.base00 })
hi("TelescopePromptNormal", { fg = p.base05, bg = p.base01 })
hi("TelescopePromptBorder", { fg = p.base0D, bg = p.base01 })
hi("TelescopeResultsNormal", { fg = p.base05, bg = p.base00 })
hi("TelescopeResultsBorder", { fg = p.base0D, bg = p.base00 })
hi("TelescopePreviewNormal", { fg = p.base05, bg = p.base00 })
hi("TelescopePreviewBorder", { fg = p.base0D, bg = p.base00 })
hi("TelescopeSelection", { fg = p.base05, bg = p.base02, bold = true })
hi("TelescopeMatching", { fg = p.base0A, bold = true })

hi("CmpItemAbbr", { fg = p.base05 })
hi("CmpItemAbbrMatch", { fg = p.base0D, bold = true })
hi("CmpItemAbbrMatchFuzzy", { fg = p.base0C, bold = true })
hi("CmpItemKind", { fg = p.base0E })
hi("CmpItemMenu", { fg = p.base04 })

-- Terminal ANSI colors matching Xresources / st Base16 mapping
vim.g.terminal_color_0 = p.base00
vim.g.terminal_color_1 = p.base08
vim.g.terminal_color_2 = p.base0B
vim.g.terminal_color_3 = p.base0A
vim.g.terminal_color_4 = p.base0D
vim.g.terminal_color_5 = p.base0E
vim.g.terminal_color_6 = p.base0C
vim.g.terminal_color_7 = p.base05
vim.g.terminal_color_8 = p.base03
vim.g.terminal_color_9 = p.base08
vim.g.terminal_color_10 = p.base0B
vim.g.terminal_color_11 = p.base0A
vim.g.terminal_color_12 = p.base0D
vim.g.terminal_color_13 = p.base0E
vim.g.terminal_color_14 = p.base0C
vim.g.terminal_color_15 = p.base07
