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
-- Set default layout for all tags
oxwm.set_layout("dwindle")
-- Color palette - loads matugen generated colors if available, with tokyonight fallback
package.path = os.getenv("HOME") .. "/.cache/matugen/?.lua;" .. package.path
local ok, colors = pcall(require, "colors")
if not ok then
    colors = require("tokyonight")
end
-- local tags = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local tags = { "[1]", "[2]", "[3]", "[4]", "[5]", "[6]", "[7]", "[8]", "[9]" } -- Example of nerd font icon tags
local bar_font = "JetBrainsMono Nerd Font Propo:style=Bold:size=12"
-- Unified block color matching matugen Material You palette with distinct divider color
local block_color = colors.block_fg or colors.blue or colors.light_blue
local divider_color = colors.sep or colors.grey

local blocks = {
    oxwm.bar.block.shell({
        -- Icon legend: 󰥅 = Conservation Active, 󰅖 = Off
        format = "{}",
        command =
        "sudo legion_cli --donotexpecthwmon batteryconservation-status | grep -q 'True' && echo '󰥅 On' || echo '󰅖 Off'",
        interval = 30,
        color = block_color,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = divider_color,
        underline = false,
    }),
    oxwm.bar.block.battery({
        battery_name = "BAT1",
        format = "Bat: {}%",
        charging = "⚡ Bat: {}%",
        discharging = "- Bat: {}%",
        full = "✓ Bat: {}%",
        interval = 10,
        signal = 1,
        color = block_color,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = divider_color,
        underline = false,
    }),
    oxwm.bar.block.shell({
        format = " {}",
        command = "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}'",
        interval = 1,
        color = block_color,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = divider_color,
        underline = false,
    }),
    oxwm.bar.block.ram({
        format = "󰍛 Ram: {used}/{total} GB",
        interval = 5,
        color = block_color,
        underline = true,
    }),
    oxwm.bar.block.static({
        text = "│",
        interval = 999999999,
        color = divider_color,
        underline = false,
    }),
    oxwm.bar.block.datetime({
        format = "󰸘 {}",
        date_format = "%a, %b %d - %H:%M:%S %Z",
        interval = 1,
        color = block_color,
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
oxwm.set_layout_symbol("normie", "[N]")
oxwm.set_layout_symbol("tabbed", "[=]")
oxwm.set_layout_symbol("dwindle", "[DW]")

-------------------------------------------------------------------------------
-- Appearance
-------------------------------------------------------------------------------
oxwm.border.set_width(2)
oxwm.border.set_focused_color(colors.green)
oxwm.border.set_unfocused_color(colors.grey)
-- Smart Enabled = No border if 1 window
oxwm.gaps.set_smart(true)
-- Inner gaps (horizontal, vertical) in pixels
oxwm.gaps.set_inner(6, 6)
-- Outer gaps (horizontal, vertical) in pixels
oxwm.gaps.set_outer(6, 6)
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
-- 1 is browser
-- 2 is second working window
-- 3 is third working window (usually anki)
-- 4 is games
-- 5 is video players
-- 6 is discord / talking
--
oxwm.rule.add({ instance = "gimp", floating = true })
oxwm.rule.add({ instance = "btop", floating = true })
oxwm.rule.add({ class = "firefox", tag = 1 })
oxwm.rule.add({ instance = "obsidian", tag = 2 })
oxwm.rule.add({ instance = "anki", tag = 3 })
oxwm.rule.add({ instance = "steam", tag = 4 })
oxwm.rule.add({ instance = "lutris", tag = 4 })
oxwm.rule.add({ instance = "sober", tag = 4 })
oxwm.rule.add({ instance = "slack", tag = 3 })
oxwm.rule.add({ instance = "mpv", tag = 5 })
oxwm.rule.add({ instance = "discord", tag = 6 })
-- making sure that the file copy window doesnt tile
oxwm.rule.add({ instance = "ripdrag", floating = true })
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
oxwm.bar.set_scheme_normal(colors.fg, colors.bg, colors.grey)
-- Occupied tags
oxwm.bar.set_scheme_occupied(colors.blue, colors.bg, colors.cyan)
-- Currently selected tag
oxwm.bar.set_scheme_selected(colors.blue, colors.red, colors.purple)

-- OR directly set an explicit height in pixels (if supported by your build)
-- oxwm.bar.set_height(35)

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
-- Restore last matugen wallpaper and colors across reboots, with fallback
oxwm.autostart(
    "sh -c 'if [ -f ~/.cache/matugen/colors.lua ] && [ -f ~/.cache/matugen/wallpaper ]; then feh --bg-scale \"$(cat ~/.cache/matugen/wallpaper)\"; else ~/nixos-dotfiles/scripts/theme-switch.sh --restore || (test -f ~/.fehbg && ~/.fehbg) || feh --bg-scale ~/nixos-dotfiles/walls/2560x1600p/tokyo-text.png; fi'")
oxwm.autostart("dunst") -- make sure dunst is running for the notifications
-- oxwm.autostart("nm-applet")
