---@meta
-------------------------------------------------------------------------------
-- OXWM Configuration File
-------------------------------------------------------------------------------
---Load type definitions for LSP
---@module 'oxwm'
-------------------------------------------------------------------------------
-- Variables
-------------------------------------------------------------------------------
-- Define your variables here for easy customization throughout the config.
-- This makes it simple to change keybindings, colors, and settings in one place.
-- Modifier key: "Mod4" is the Super/Windows key, "Mod1" is Alt
local modkey = "Mod4"
-- Terminal emulator command (defualts to alacritty)
local terminal = "st"
-- Color palette - customize these to match your theme
-- Alternatively you can import other files in here, such as
-- local colors = require("colors.lua") and make colors.lua a file
-- in the ~/.config/oxwm directory
local colors = require("tokyonight");
-- local colors = require("colors.custom-colors");
-- local tags = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local tags = { "", "󰺷", "", "󰰏", "󰟿", "󱇤", "", "󱘶", "󰧮" } -- Example of nerd font icon tags
local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=12"
local blocks = {
    oxwm.bar.block.shell({
        format = " {}",
        command = "uname -n",
        interval = 3600,
        color = colors.red,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),
    oxwm.bar.block.ram({
        format = "󰍛 Ram: {used}/{total} GB",
        interval = 5,
        color = colors.light_blue,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),
    oxwm.bar.block.datetime({
        format = "󰸘 {}",
        date_format = "%a, %b %d - %H:%M:%S",
        interval = 1,
        color = colors.cyan,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = colors.sep,
        underline = false,
    }),
    -- Uncomment to add battery status (useful for laptops)
    oxwm.bar.block.battery({
        battery_name = "BAT1",
        format = "Bat: {}%",
        charging = "⚡ Bat: {}%",
        discharging = "- Bat: {}%",
        full = "✓ Bat: {}%",
        interval = 30,
        color = colors.green,
        underline = true,
    }),
};
-------------------------------------------------------------------------------
-- Basic Settings
-------------------------------------------------------------------------------
oxwm.set_terminal(terminal)
oxwm.set_modkey(modkey)
oxwm.set_tags(tags)
-------------------------------------------------------------------------------
-- Layouts
-------------------------------------------------------------------------------
oxwm.set_layout_symbol("tiling", "[T]")
oxwm.set_layout_symbol("normie", "[F]")
oxwm.set_layout_symbol("tabbed", "[=]")
-------------------------------------------------------------------------------
-- Appearance
-------------------------------------------------------------------------------
oxwm.border.set_width(2)
oxwm.border.set_focused_color(colors.purple)
oxwm.border.set_unfocused_color(colors.grey)
-- Smart Enabled = No border if 1 window
oxwm.gaps.set_smart(true)
-- Inner gaps (horizontal, vertical) in pixels
oxwm.gaps.set_inner(5, 5)
-- Outer gaps (horizontal, vertical) in pixels
oxwm.gaps.set_outer(5, 5)
-------------------------------------------------------------------------------
-- Window Rules
-------------------------------------------------------------------------------
-- Rules allow you to automatically configure windows based on their properties
-- You can match windows by class, instance, title, or role
-- Available properties: floating, tag, fullscreen, etc.
--
-- Common use cases:
-- - Force floating for certain applications (dialogs, utilities)
-- - Send specific applications to specific workspaces
-- - Configure window behavior based on title or class
-- Examples (uncomment to use):
oxwm.rule.add({ instance = "gimp", floating = true })
oxwm.rule.add({ instance = "sober", tag = 2 })
oxwm.rule.add({ class = "firefox", tag = 3 })
oxwm.rule.add({ instance = "slack", tag = 4 })
oxwm.rule.add({ instance = "discord", tag = 5 })
-- To find window properties, use xprop and click on the window
-- WM_CLASS(STRING) shows both instance and class (instance, class)
-------------------------------------------------------------------------------
-- Status Bar Configuration
-------------------------------------------------------------------------------
-- Font configuration
oxwm.bar.set_font(bar_font)
-- Set your blocks here (defined above)
oxwm.bar.set_blocks(blocks)
-- Bar color schemes (for workspace tag display)
-- Parameters: foreground, background, border
-- Unoccupied tags
oxwm.bar.set_scheme_normal(colors.fg, colors.bg, "#444444")
-- Occupied tags
oxwm.bar.set_scheme_occupied(colors.blue, colors.bg, colors.cyan)
-- Currently selected tag
oxwm.bar.set_scheme_selected(colors.blue, colors.bg, colors.purple)
-------------------------------------------------------------------------------
-- Keybindings (loaded from separate file)
-------------------------------------------------------------------------------
local setup_keys = require("keybinds.keys")
setup_keys(modkey)
-------------------------------------------------------------------------------
-- Modules
-------------------------------------------------------------------------------
-- Load and configure xsecurelock settings module
local screen_lock = require("modules.screen-lock")
screen_lock.setup()
-------------------------------------------------------------------------------
-- Autostart
-------------------------------------------------------------------------------
-- Commands to run once when OXWM starts
-- Uncomment and modify these examples, or add your own
-- oxwm.autostart("picom")
oxwm.autostart("feh --bg-scale ~/Walls/tokyo-text.png")
oxwm.autostart("dunst") -- make sure dunst is running for the notifications
-- oxwm.autostart("nm-applet")
