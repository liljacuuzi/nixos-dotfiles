---@meta
---@module 'oxwm'

-- Returns a function that registers all keybinds + keychords.
-- Pass modkey from the main config so everything stays consistent.
return function(modkey)
    -------------------------------------------------------------------------------
    -- Keybindings
    -------------------------------------------------------------------------------
    -- Basic window management
    oxwm.key.bind({ modkey }, "Return", oxwm.spawn_terminal())

    -- Launch launcher
    oxwm.key.bind({ modkey }, "D", oxwm.spawn({ "sh", "-c", "rofi -show drun" }))

    -- Copy screenshot to clipboard
    oxwm.key.bind({ modkey }, "S", oxwm.spawn({ "sh", "-c", "maim -s | xclip -selection clipboard -t image/png" }))

    oxwm.key.bind({ modkey }, "Q", oxwm.client.kill())

    -- Keybind overlay
    oxwm.key.bind({ modkey, "Shift" }, "Slash", oxwm.show_keybinds())

    -- Window state toggles
    oxwm.key.bind({ modkey, "Shift" }, "F", oxwm.client.toggle_fullscreen())
    oxwm.key.bind({ modkey, "Shift" }, "Space", oxwm.client.toggle_floating())

    -- Layout management
    oxwm.key.bind({ modkey }, "C", oxwm.layout.set("tiling"))
    oxwm.key.bind({ modkey }, "N", oxwm.layout.cycle())

    -- Master area controls
    oxwm.key.bind({ modkey }, "H", oxwm.set_master_factor(-5))
    oxwm.key.bind({ modkey }, "L", oxwm.set_master_factor(5))
    oxwm.key.bind({ modkey }, "I", oxwm.inc_num_master(1))
    oxwm.key.bind({ modkey }, "P", oxwm.inc_num_master(-1))

    -- Gaps toggle
    oxwm.key.bind({ modkey }, "A", oxwm.toggle_gaps())

    -- Window manager controls
    oxwm.key.bind({ modkey, "Shift" }, "Q", oxwm.quit())
    oxwm.key.bind({ modkey, "Shift" }, "R", oxwm.restart())

    -- Focus movement
    oxwm.key.bind({ modkey }, "J", oxwm.client.focus_stack(1))
    oxwm.key.bind({ modkey }, "K", oxwm.client.focus_stack(-1))

    -- Window movement (swap)
    oxwm.key.bind({ modkey, "Shift" }, "J", oxwm.client.move_stack(1))
    oxwm.key.bind({ modkey, "Shift" }, "K", oxwm.client.move_stack(-1))

    -- lock screen
    oxwm.key.bind({ modkey, "Shift" }, "L",
        oxwm.spawn({ "sh", "-c", "oxwm-lock" }))

    -- Multi-monitor
    oxwm.key.bind({ modkey }, "Comma", oxwm.monitor.focus(-1))
    oxwm.key.bind({ modkey }, "Period", oxwm.monitor.focus(1))
    oxwm.key.bind({ modkey, "Shift" }, "Comma", oxwm.monitor.tag(-1))
    oxwm.key.bind({ modkey, "Shift" }, "Period", oxwm.monitor.tag(1))

    -- Workspace (tag) navigation
    oxwm.key.bind({ modkey }, "1", oxwm.tag.view(0))
    oxwm.key.bind({ modkey }, "2", oxwm.tag.view(1))
    oxwm.key.bind({ modkey }, "3", oxwm.tag.view(2))
    oxwm.key.bind({ modkey }, "4", oxwm.tag.view(3))
    oxwm.key.bind({ modkey }, "5", oxwm.tag.view(4))
    oxwm.key.bind({ modkey }, "6", oxwm.tag.view(5))
    oxwm.key.bind({ modkey }, "7", oxwm.tag.view(6))
    oxwm.key.bind({ modkey }, "8", oxwm.tag.view(7))
    oxwm.key.bind({ modkey }, "9", oxwm.tag.view(8))

    -- Move focused window to workspace N
    oxwm.key.bind({ modkey, "Shift" }, "1", oxwm.tag.move_to(0))
    oxwm.key.bind({ modkey, "Shift" }, "2", oxwm.tag.move_to(1))
    oxwm.key.bind({ modkey, "Shift" }, "3", oxwm.tag.move_to(2))
    oxwm.key.bind({ modkey, "Shift" }, "4", oxwm.tag.move_to(3))
    oxwm.key.bind({ modkey, "Shift" }, "5", oxwm.tag.move_to(4))
    oxwm.key.bind({ modkey, "Shift" }, "6", oxwm.tag.move_to(5))
    oxwm.key.bind({ modkey, "Shift" }, "7", oxwm.tag.move_to(6))
    oxwm.key.bind({ modkey, "Shift" }, "8", oxwm.tag.move_to(7))
    oxwm.key.bind({ modkey, "Shift" }, "9", oxwm.tag.move_to(8))

    -- Combo view (toggle tag visibility)
    oxwm.key.bind({ modkey, "Control" }, "1", oxwm.tag.toggleview(0))
    oxwm.key.bind({ modkey, "Control" }, "2", oxwm.tag.toggleview(1))
    oxwm.key.bind({ modkey, "Control" }, "3", oxwm.tag.toggleview(2))
    oxwm.key.bind({ modkey, "Control" }, "4", oxwm.tag.toggleview(3))
    oxwm.key.bind({ modkey, "Control" }, "5", oxwm.tag.toggleview(4))
    oxwm.key.bind({ modkey, "Control" }, "6", oxwm.tag.toggleview(5))
    oxwm.key.bind({ modkey, "Control" }, "7", oxwm.tag.toggleview(6))
    oxwm.key.bind({ modkey, "Control" }, "8", oxwm.tag.toggleview(7))
    oxwm.key.bind({ modkey, "Control" }, "9", oxwm.tag.toggleview(8))

    -- Multi-tag (window on multiple tags)
    oxwm.key.bind({ modkey, "Control", "Shift" }, "1", oxwm.tag.toggletag(0))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "2", oxwm.tag.toggletag(1))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "3", oxwm.tag.toggletag(2))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "4", oxwm.tag.toggletag(3))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "5", oxwm.tag.toggletag(4))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "6", oxwm.tag.toggletag(5))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "7", oxwm.tag.toggletag(6))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "8", oxwm.tag.toggletag(7))
    oxwm.key.bind({ modkey, "Control", "Shift" }, "9", oxwm.tag.toggletag(8))

    -------------------------------------------------
    -------------------------------------------------------------------------------
    -- Media / Hardware keys (uses your volume-notify / brightness-notify / opacity-notify)
    -------------------------------------------------------------------------------
    -- Volume  (force PATH so Home Manager binaries are found)
    oxwm.key.bind({}, "XF86AudioRaiseVolume",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; volume-notify up" }))
    oxwm.key.bind({}, "XF86AudioLowerVolume",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; volume-notify down" }))
    oxwm.key.bind({}, "XF86AudioMute",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; volume-notify mute" }))

    -- Brightness
    oxwm.key.bind({}, "XF86MonBrightnessUp",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; brightness-notify up" }))
    oxwm.key.bind({}, "XF86MonBrightnessDown",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; brightness-notify down" }))

    -- Opacity
    oxwm.key.bind({ modkey, "Control" }, "Up",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; opacity-notify up" }))
    oxwm.key.bind({ modkey, "Control" }, "Down",
        oxwm.spawn({ "sh", "-c", "export PATH=\"$HOME/.nix-profile/bin:$PATH\"; opacity-notify down" }))

    -------------------------------------------------------------------------------
    -- Keychords
    -------------------------------------------------------------------------------
    oxwm.key.chord({
        { { modkey }, "Space" },
        { {},         "T" }
    }, oxwm.spawn_terminal())

    oxwm.key.chord({
        { { modkey }, "F" },
        { {},         "B" }
    }, oxwm.spawn({ "sh", "-c", "$HOME/repos/dmenu-scripts/bookmarks-dmenu.sh" }))

    oxwm.key.chord({
        { { modkey }, "F" },
        { {},         "F" }
    }, oxwm.spawn({ "sh", "-c", "$HOME/repos/dmenu-scripts/repos-dmenu.sh" }))

    oxwm.key.chord({
        { { modkey }, "F" },
        { {},         "O" }
    }, oxwm.spawn({ "sh", "-c", "$HOME/repos/dmenu-scripts/tmux-dmenu.sh" }))
end
