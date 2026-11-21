# Model Setup & Architecture Guide (`nixos-dotfiles`)

This document is a reference for future AI sessions working on this NixOS configuration (`nixos-laptop`, Lenovo Legion 15IAX11 with OLED panel, `oxwm` on X11/XLibre, `st-flexipatch`, `SilentSDDM`, and `matugen 4.2.0`). It consolidates every user prompt, final working change, design philosophy, and hard-won gotcha across **all** AGY conversations for this repo (`f72fd15e`, `3938e174`, `83a39ebd`, `14d826cd`, `285ec380`, `9505f080`, `8590e3a6`, `d50f9e47`, `21a190c5`, `d17178aa`, `4d2794d6`/`dad00d6`, `7df1fd68`/`1f5fce4`+`c945fe9`+`a117aeb`, `afb9a93c`, `e94872b6`, `2e01c21b`, `4421572a`, `f069584a`). Superseded intermediate setups (such as `pywal16`, the initial Base16 shell templates, and `xsecurelock`) are intentionally omitted in favor of the final working configuration.

---

## How to Update This Document (For Future AI Sessions)

This file exists to **minimize token usage in future LLM sessions** by providing a dense, accurate architectural reference so future sessions do not need to re-read history or re-investigate solved problems. When documenting new work here, follow these rules:

1. **Final Working Solution Only:** Record only the final, verified architecture. Omit failed experiments, intermediate debugging, and superseded setups (replace outdated entries if a newer solution supersedes them).
2. **Capture Prompts & User Decisions:** Add the conversation ID to the intro list and append a concise numbered entry under **Summary of User Prompts & Approved Requirements** containing the key user prompts that led to the solution and any explicit user choices/tradeoffs.
3. **Explain the Philosophy & Decisions:** Add a new **Part N** section with:
   - **Design Philosophy & Decisions:** *Why* this approach was chosen, key technical/security/power tradeoffs, and why obvious alternatives don't work on this system.
   - **Files Changed:** Exact file paths and a compact summary of what each file owns.
4. **Update Quick Reference Gotchas:** Add any non-obvious, reusable constraints (NixOS wrapper quirks, hardware limits, path rules) to **Quick Reference & Token-Saving Gotchas for Future Sessions** so future agents avoid known traps on the first try.
5. **Stay Concise:** Prefer tight, high-signal bullets over prose or full code dumps—link or reference exact file paths instead of duplicating configs.

---

## System & Workflow Conventions

- **Host / Rebuild:** `nixos-laptop` via `nrs` (`sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-laptop`).
- **Window Manager & Display:** `oxwm` (X11 / XLibre). The user frequently uses **workspace 1** on `DISPLAY=:0` (e.g., watching YouTube); **always run visual tests and screenshots inside an isolated `Xvfb :99` display** so `:0` is never disturbed.
- **Dynamic Theming Engine:** `matugen 4.2.0` invoked by `scripts/theme-switch.sh` (`themeswitch`) using `MATUGEN_SCHEME="scheme-fidelity"` and `--mode dark --source-color-index 0`. Generated files live in `~/.cache/matugen/`.
- **Hardware Constraint (OLED):** The laptop panel is OLED, so idle burn-in protection (`xscreensaver` playing after 60s of lockscreen inactivity) must be preserved.

---

## Summary of User Prompts & Approved Requirements (Sourced by Conversation)

0. **Pre-Matugen Foundation & Hardware/App Tweaks (`67031b1`–`e1923b0`):**
   - **Dynamic theming workflow, `st` dev shell & `themeswitch` alias** ([`f72fd15e`](conversation://f72fd15e-6936-4f46-a42b-7d30839ed686), 2026-11-10):
     - *"Look at the files inside `config`, `config/oxwm/tokyonight.lua`, `home.nix`, and `configuration.nix` to see how would I implement a script using pywal16 to dynamically change the color palette for my window manager oxwm, st, rofi, btop, dunst, nvim using templates"* → *"put pywal16 in home.nix"* (declarative, never `nix-env`) → *"in flake.nix, I already have a nix-shell for this labelled something like `nix develop .#suckless`"* → *"when a new window is spawned for something like st itself, btop or yazi, it resorts back to my default theme, how can this be fixed, and how would I also have this theme automatically apply for firefox as well?"* → *"create a shortcut in bash in home.nix so that `~/nixos-dotfiles/scripts/theme-switch.sh` gets shortened to `themeswitch` and then I can just pipe whatever image I want, and make sure wallpapers persist across reboots."*
   - **Wallpapers moved into repo & power-rule refresh-rate repaint** ([`3938e174`](conversation://3938e174-d6a8-4d95-a027-f06bfd9b85a2), 2026-11-10):
     - *"could you move my walls in `~/Walls` to my config `~/nixos-dotfiles`, and make sure my lockscreen still works"* → *"could you do the powerrule switches so that it adheres to the themeswitch script we made previous conversation."*
   - **OXWM bar accent colors, distinct shell colors & Neovim transparency** ([`83a39ebd`](conversation://83a39ebd-5052-4f4e-9303-c23ae15e8891), 2026-11-10):
     - *"make sure that no matter what wallpaper I choose that the colors of the blocks are all the same (but keep the color of block text and icons different from the divider color separating the blocks in oxwm) and make sure that inside my shell, the colors are distinct for the files but still in line with any wallpaper I select"* → *"the block color seems to always stay white, change just that"* → *"fix nvim's transparency, as it is currently not transparent but it used to be as transparent as st (`alpha = 0.90`)."*
   - **OXWM centered time-block check** ([`14d826cd`](conversation://14d826cd-e6e2-482a-9ddb-a09c085d5e9e), 2026-11-10):
     - *"would it be possible for oxwm to have the time block be centered in the middle of the task bar, or is that currently not natively possible with oxwm bar?"* *(Confirmed not natively possible.)*
   - **Bluetooth off on battery / restored on AC** ([`285ec380`](conversation://285ec380-19e1-4f9b-a1d7-df1aff58d9fd), 2026-11-10):
     - *"does bluetooth run while in power-saving mode (not plugged into wall) because I don't need access to bluetooth while I'm not connected to wall"* → *"do Option A, and include the optional step in it to restore bluetooth on ac mode."*
   - **`Papirus-Dark` icons, live GTK/Qt/Anki/PCManFM-Qt theming & `~/Walls` cleanup** ([`9505f080`](conversation://9505f080-0823-46e8-bbda-9719d3a6928b), 2026-11-10):
     - *"add papirus-dark icons to my config so that my entire system uses these icons — do this declaratively in the nixos fashion"* → *"include gtk-3.0 and gtk-4.0 in `home.nix` and integrate GTK theming"* → *"do the same thing for qt apps like anki"* → *"the only thing that requires an app restart are gtk related things (like lutris or the right click menu in firefox); make this a live change declaratively"* → *"the header color around decks/add/browse/sync in anki seems delayed to the previous themeswitch — fix it"* → *"pcmanfm-qt doesn't use theming"* → *"does `~/Walls` still need to be kept or is it fine to delete?"* *(Confirmed safe to delete.)*
   - **Yazi USB mount shortcut** ([`8590e3a6`](conversation://8590e3a6-09b2-4389-b783-a0545b81d867), 2026-11-10):
     - *"make it so that yazi has a shortcut that automatically goes to the usb drive point in my system `/run/media/smalldog/`. Do this declaratively within `config/yazi/`."*
   - **Declarative `SilentSDDM`** ([`d50f9e47`](conversation://d50f9e47-469f-40d3-a244-e586daa7cea2), 2026-11-11):
     - *"Is it possible to do all the configuration for a login manager like sddm or ly inside `configuration.nix`?"* → *"use `silentSDDM` in `configuration.nix`, configured with dynamic themeing and the same background image as `themeswitch`"* → *"fix duplicate `environment.systemPackages` error and verify why reboot still showed default config."*
   - **Idle lockscreen timing (`xidlehook` + 60s OLED `xscreensaver`)** ([`21a190c5`](conversation://21a190c5-3705-4c55-93a2-8854aa444892), 2026-11-11):
     - *"/plan optimize the lockscreen config with minimal resources and a screensaver"* → *"keep at 5 min total, warning at 4m30s, and 60s before transitioning to xscreensaver"* → *"fix the 30s pre-lock warning notification so it functions as before, and fix the counter switching to screensaver in much less than 60s."*
   - **`st` Sixel support without finalizing `st-flexipatch`** ([`d17178aa`](conversation://d17178aa-f593-400e-a594-2ab2c098bb4a), 2026-11-12):
     - *"make it so that st supports sixel, beware that my version of st uses st-flexipatch, and I want to keep st-flexipatch if I want to change anything else in the future so don't use `flexipatch-finalizer` at all."*

1. **Pywal16 → Matugen v4.2.0 Migration, Desktop/App Material You Theming & Runtime Fixes (`dad00d6`, [`4d2794d6`](conversation://4d2794d6-7ab7-4935-945b-8f9c7735547b), 2026-11-12):**
   - *Prompts:*
     - *"/plan port my current configuration from pywal16 to matugen's Material You theming across all apps (`SilentSDDM`, `Xresources`, `st`, `dunst`, `oxwm`, `Neovim`, `Firefox` via `MatugenFox`, `Anki`, `PCManFM-Qt`, `GTK`, plus `Qt` and `Obsidian` via `Simorg2002/obsidian-matugen-template`), including proper validation testing for each port."*
     - *"only write Obsidian to `matugen-colors.css` in `snippets/`, use `scheme-fidelity` and tell me where to change it later, and delete legacy pywal files once ported."*
     - *"use MatugenFox to add Material You theming to YouTube, YouTube Music, and GitHub; also fix `pcmanfm-qt` staying stuck on one color palette whether closed or running during `themeswitch`."*
     - *"fix Yazi startup error `Failed to read keymap "/home/smalldog/.config/yazi/keymap.toml": Too many levels of symbolic links (os error 40)` and ensure `nvim` becomes the default editor for Yazi through the simplest means possible."*
     - *"fix `dunst` not being dynamically updated as it's stuck on default colors."*
     - *"Yazi doesn't do a full switch on `themeswitch`"* *(later finalized via `scripts/yazi-matugen.sh` in Part 7).*
   - *User decisions (still active in final config):*
     - Use **`scheme-fidelity`** (`MATUGEN_SCHEME` in `scripts/theme-switch.sh`) and delete all legacy `pywal` files.
     - Theme Firefox via **`MatugenFox`** + custom Material You CSS for **YouTube**, **YouTube Music**, and **GitHub**.
     - Write Obsidian theming **exclusively** to `<vault>/.obsidian/snippets/matugen-colors.css`.
     - Set `nvim` as Yazi's default editor via `config/yazi/yazi.toml` `[opener].edit`.
     - *(Note: the initial Base16 shell/terminal split and `xsecurelock` lockscreen from `dad00d6` were later replaced by Parts 2 & 3 below.)*

2. **Shell & Terminal Regular Matugen Migration (`1f5fce4`, [`7df1fd68`](conversation://7df1fd68-1f62-443b-81dd-acd93547e3f2), 2026-11-19):**
   - *Prompts:*
     - *"/plan make a git branch named `shell-matugen` switching all shell and shell-based programs (`st`, `btop`, `neovim`, `yazi`, etc.) from `matugen base16` to regular `matugen` using `InioX/matugen-themes` or public git repos. Keep in mind I use workspace 1 to watch YouTube while you work."*
     - *"use `Senal-D-A-Gunaratna/matugen.nvim`; use Material `surface`/`on_surface` tokens for backgrounds, foregrounds, and grayscale slots (`color0`, `color7`, `color8`, `color15`) paired with `blend = true` custom colors (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`) and `auto_lightness`; include `fzf`, `bat`, and `alacritty`."*

3. **`qylock` (`material-you-dark`) Screenlock + Matugen + OLED Protection (`c945fe9`, [`7df1fd68`](conversation://7df1fd68-1f62-443b-81dd-acd93547e3f2), 2026-11-19):**
   - *Prompts:*
     - *"/plan replace my current screenlock solution with `Darkkal44/qylock` (`material-you-dark`) integrated with Matugen so my wallpaper becomes the lockscreen and qylock colors adapt via Matugen."*
     - *"don't get rid of `xscreensaver`. Since my screen is OLED, I need `xscreensaver` to play so I don't get burn-in."* → *"merge the branches into main."*
   - *User decisions:* Display the **raw active wallpaper** (crisp + dark scrim), replace **only the desktop screenlock** (`oxwm-lock`, keeping `SilentSDDM`), and **keep `xscreensaver`** playing while locked.

4. **Password-Protected Power & Reboot on Lockscreen (`a117aeb`, [`7df1fd68`](conversation://7df1fd68-1f62-443b-81dd-acd93547e3f2), 2026-11-19):**
   - *Prompts:*
     - *"/plan is there a way to add protection so that when I'm in my lockscreen no random person can come and just shut down / reboot my laptop. Don't implement anything yet, just plan."*
     - *"execute the plan after verifying it's true for the Legion 15IAX11 that the motherboard shuts down after holding the power button 5–10 seconds regardless of OS choices."*
     - *"create `model-setup.md` in `model_knowledge/` describing every change and the philosophy behind only the final working solution, including what I prompted."*
   - *User decisions:* Gate **POWER** and **REBOOT** behind PAM password confirmation (`Escape` cancels); keep **SLEEP** passwordless.

5. **Firefox Tab Notifications — Click-to-Focus & Markdown Formatting ([`2e01c21b`](conversation://2e01c21b-e994-42dd-9ea6-77db22e37414), 2026-11-21):**
   - *Prompts:*
     - *"fix the notification for Firefox so when tabs send a notification to desktop, I immediately go to Firefox and to that specific tab, and make sure formatting doesn't just display raw characters like `*` (e.g., Gemini chat notifications)."*
     - *"is this implementation performant compared to standard, should I expect any noticeable lag?"*
   - *User decisions:* Trigger jump on **left-click** (not automatically on arrival).

6. **Lenovo Legion 15IAX11 Native OpenRGB, Matugen Sync & Screen-Brightness Tracking ([`4421572a`](conversation://4421572a-3a1e-4a6a-93a9-9a29ea612f68), 2026-11-21):**
   - *Prompts:*
     - *"/plan see if my Legion 15IAX11 could possibly have RGB customization on my setup, ideally via the OpenRGB already running on my system."*
     - *"use native OpenRGB, match Matugen, turn off RGB keyboard when not plugged in to conserve power, and verify whether I can still switch profiles with `Fn + Space`."*
     - *"whenever I try a `themeswitch`, the keyboard always seems to turn white no matter what — fix that, and match keyboard RGB brightness to screen brightness (`xrandr`)."*
     - *"write all final working changes, philosophy, and prompts to `model_knowledge/model-setup.md`."*

7. **OXWM Volume Block, Muted Notification & Live Yazi Theme Reload ([`afb9a93c`](conversation://afb9a93c-89cc-4866-b24a-552e7e54de62), 2026-11-21):**
   - *Prompts:*
     - *"replace the command that runs for the volume block in `config/oxwm` with a script in `scripts/` that has minimal on-change delay and switches to a muted icon from JetBrainsMono Nerd Font while keeping the current unmuted icon."*
     - *"are you sure the 1s interval can't be bypassed by not setting an interval or something?"* *(Confirmed via OXWM source that `interval = 0` disables updates and `1` is the minimum.)*
     - *"have my volume notification show `(muted)` in brackets next to the bold **Volume** header, preferably not bold, cleanly using `config/dunst`."*
     - *"make sure Yazi properly switches themes, as it has sometimes failed to switch or fallen back to default Tokyo Night — use screenshots and test extensively."*

8. **NixOS `nrs` Evaluation Warning Cleanup ([`e94872b6`](conversation://e94872b6-271f-41e6-b06e-f9b6851894f3), 2026-11-21):**
   - *Prompt:* *"fix the naming errors in my config that cause the evaluation warnings when I do `nrs`."*

9. **`btop` Dual-GPU Monitoring (NVIDIA RTX 5060 + Intel iGPU) ([`f069584a`](conversation://f069584a-9b3b-4644-966a-a8eab6bdd742), 2026-11-21):**
   - *Prompts:*
     - *"/plan can you figure out why btop doesnt display my gpu(s), discrete or integrated. Use screenshots if you need to fix this issue. Reference `model_knowledge/model-setup.md` if needed."*
     - *"will changing to btop-cuda mess up my themeing scripts for btop, just by looking at `model_knowledge/model-setup.md`?"*
     - *"do i have to change btop in this `configs = { ... btop = \"btop\"; ... }`?"*
     - *"alright do ahead with the changes"* → *"add this to `model_knowledge/model-setup.md` by showing the philosophy behind final solution, decisions made and the user prompts that got you there, and add polished instructions at the top for updating it so future LLM sessions cost fewer tokens."*
   - *User decisions:* Use `pkgs.btop-cuda` + least-privilege `security.wrappers.btop` (`cap_perfmon+ep`, `root:wheel`), show both dedicated GPU boxes by default (`shown_boxes = "cpu mem net proc gpu0 gpu1"`), clear `custom_gpu_name0`, and leave `btop = "btop"` in `home.nix`'s `configs` symlink map untouched.

---

## Part 0: Core System Foundation, Power Management, `st-flexipatch` & OXWM Constraints (`67031b1`–`e1923b0`)

### Design Philosophy
- **Consolidated Wallpapers & Power-Rule Sync:** All wallpapers live in `~/nixos-dotfiles/walls/` (`~/Walls` is unused and not referenced anywhere). Power-rule display refresh-rate switches repaint the active wallpaper from `~/.cache/matugen/wallpaper` rather than reverting to a static image.
- **Battery Power Conservation (`battery-mode` / `ac-mode`):** `hardware.bluetooth = { enable = true; powerOnBoot = false; }` still leaves `bluetoothd` running if enabled later. `systemd.services.battery-mode` runs `rfkill block bluetooth` and stops `bluetooth.service` on battery, while `ac-mode` runs `rfkill unblock bluetooth` and restarts `bluetooth.service` on AC.
- **Keep `st-flexipatch` Editable (Never Finalize):** `config/st/` uses `st-flexipatch` (`ALPHA_PATCH=1` with `alpha = 0.90`, `XRESOURCES_RELOAD_PATCH=1` for `SIGUSR1`, `SIXEL_PATCH=1` with `imlib2`). Never run `flexipatch-finalizer`, so future patches remain easy to toggle. Manual builds use `nix develop .#suckless` (which includes `imlib2` and `libXrender`); NixOS builds `st` via `modules/suckless.nix`.
- **Declarative `Papirus-Dark` Icons Everywhere:** `home.nix` links `pkgs.papirus-icon-theme` into both `~/.icons/{Papirus-Dark,Papirus}` and `~/.local/share/icons/{Papirus-Dark,Papirus}` so GTK, Qt (`qt5ct`/`qt6ct`), Rofi, Dunst, and Flatpak apps all resolve the same icon theme.
- **Dynamic OXWM Bar Accent & Transparency:** `config/oxwm/config.lua` uses `block_color = colors.block_fg or colors.blue or colors.light_blue` and `divider_color = colors.sep or colors.grey` so status blocks never stay static white; Neovim's `make_transparent()` keeps `Normal` transparent so `st`'s `alpha = 0.90` shows through.
- **Idle Lock & OLED Timing Chain:** `config/oxwm/modules/screen-lock.lua` runs `xidlehook` directly (do **not** wrap it in `sh -c "pkill ..."` — that broke `oxwm.autostart`): **4m30s** triggers `oxwm-lock-warn` (30s warning notification) → **5m00s** triggers `oxwm-lock` → **60s** of inactivity triggers `xscreensaver` via `oxwm-wait-input` (`libX11` `XQueryPointer` + `XQueryKeymap`, replacing `xsecurelock`'s `until_nonidle` which had a hardcoded 7s default timeout).
- **SilentSDDM Full-Schema Requirement:** SilentSDDM's Qt6 QML parser requires all component layout properties in `config/matugen/templates/silent.conf` (omitting them causes `QVariant(Invalid)` errors) and requires `GreeterEnvironment = "QML2_IMPORT_PATH=${silentSDDMTheme}/share/sddm/themes/silent/components/,QT_IM_MODULE=qtvirtualkeyboard"` in `configuration.nix`.
- **Known Upstream OXWM Bar Limitations (Do Not Re-Investigate):**
  1. **No centered bar blocks:** `src/bar/bar.zig` only implements a left zone (tags/layout) and a right-aligned block/systray zone; centering a block (e.g., time) is not natively supported.
  2. **1-second minimum polling, no signal refresh:** `src/bar/blocks/blocks.zig` compares `.toSeconds()` timestamps, disables updates when `interval == 0`, and has no `SIGRTMIN+N`/IPC push refresh — `interval = 1` is the fastest update rate OXWM supports.

### Files Changed (Still Active)
- **`configuration.nix`:** `battery-mode` / `ac-mode` Bluetooth `rfkill` + `bluetooth.service` control, `oxwm-lock-warn`, `oxwm-wait-input`, `SilentSDDM` `GreeterEnvironment`.
- **`config/st/patches.h`, `config/st/config.mk`, `modules/suckless.nix`, `flake.nix`:** `SIXEL_PATCH 1` + `imlib2` / `libXrender` wired into both `modules/suckless.nix` and `devShells.x86_64-linux.suckless`.
- **`config/oxwm/modules/screen-lock.lua`:** Direct `xidlehook` invocation (4m30s warning → 5m lock).
- **`config/yazi/keymap.toml`:** `g u` → `cd /run/media/smalldog` (USB drive mount point).
- **`home.nix`:** `themeswitch` bash alias (supports args + stdin piping) and `Papirus-Dark` symlinks.

---

## Part 1: Pywal16 → Matugen v4.2.0 Migration, Desktop/App Material You Theming & Runtime Fixes (`dad00d6`)

*(Documents only the components from `dad00d6` that remain active in the current working config; the shell/terminal Base16 templates and `xsecurelock` lockscreen were replaced in Parts 2 & 3.)*

### Design Philosophy
- **Single-Variable Scheme Control (`theme-switch.sh`):** `matugen 4.2.0` has no global `scheme` key in `config.toml`, so `MATUGEN_SCHEME="scheme-fidelity"` is centralized at the top of `scripts/theme-switch.sh` (`-t`/`--type` overrides it ad hoc, `--color` generates from a hex color, `--restore` reapplies the cached wallpaper, and stdin piping is supported). All generated cache files live in `~/.cache/matugen/`.
- **Passwordless Dynamic `SilentSDDM`:** Because `/nix/store` is immutable and SDDM runs as `sddm`, `silentSDDMTheme` symlinks `configs/matugen.conf` → `/var/cache/matugen-sddm/silent.conf` and `backgrounds/matugen.png` → `/var/cache/matugen-sddm/wallpaper.png`. `systemd.tmpfiles.rules` creates `/var/cache/matugen-sddm` owned by `smalldog:users` (`0755`, files `644`) and `system.activationScripts` seeds fallbacks, allowing `themeswitch` to update SDDM without `sudo`.
- **NixOS Wrapper Process Detection (`pgrep`/`pkill`):** NixOS wraps several binaries (`dunst` → `.dunst-wrapped`, `pcmanfm-qt` → `.pcmanfm-qt-wra` truncated at Linux's 15-char `comm` limit, plus `.btop-wrapped`/`.nvim-wrapped`). Checking only the unwrapped name caused `dunst` to never reload (spawning a duplicate daemon that exited immediately) and `pcmanfm-qt` to never restart; `scripts/theme-switch.sh` explicitly checks both unwrapped and wrapped `comm` names.
- **Declarative `MatugenFox` + Custom Material You Site CSS:** Rather than manual imperative installation, `home.nix` builds `matugenfox-native` from `Ubaidullah-Web-Dev/MatugenFox` (`rev = "1eb7365ff03c859a5be18f422e2b630e4a248ab9"`), patches `matugenfox_host.py` to also discover XDG Firefox profiles (`~/.config/mozilla/firefox`) alongside `~/.mozilla/firefox`, exposes the native messaging manifest (`matugenfox.json`), force-installs `matugenfox@ubaid.com`, and blocks `pywalfox@frewacom.org`. Custom site CSS overrides (`youtube.css`, `music.youtube.com.css`, `github.css`) live in `config/dusky_sites/` (symlinked to `~/.config/dusky_sites`) and consume the CSS variables generated into `~/.config/matugen/generated/firefox_websites.css` (polled every 2s by `matugenfox_host.py`).
- **Obsidian Snippet Isolation & Matugen v4.2.0 HSL Scale:** `config/matugen/templates/obsidian-minimal-matugen-colors.css` (adapted from `Simorg2002/obsidian-matugen-template`) outputs directly to the vault's `.obsidian/snippets/matugen-colors.css` without modifying other vault files, using Matugen v4.2.0's `0..360` hue and `0..100` saturation/lightness values (`--accent-h/s/l`).
- **Qt5 / Qt6 + `PCManFM-Qt` Dynamic Theming:** `qt5ct` (`21` palette roles/group) and `qt6ct` (`22` roles/group) use `Fusion` with `custom_palette = true` reading `~/.config/qt{5,6}ct/colors/matugen.conf` (`QT_QPA_PLATFORMTHEME="qt5ct"`). Because `pcmanfm-qt` ignores live `qt5ct` palette changes until restarted and requires explicit QSS styling for complete Material You coverage, `home.nix` wraps `pcmanfm-qt` via `symlinkJoin` to export `QT_QPA_PLATFORMTHEME="qt5ct"` and pass `-stylesheet ~/.cache/matugen/pcmanfm-qt.qss`, while `theme-switch.sh` cleanly quits and restarts running instances (preserving `--desktop` / `-d` flags).
- **Live GTK 3/4 Reload via Alternating Themes:** GTK only reloads CSS when the theme name actually changes. `home.nix` defines identical `matugen-a` and `matugen-b` themes (importing `~/.cache/matugen/colors-gtk.css`, plus `Adwaita/gtk-contained-dark.css` for GTK3) in both `~/.local/share/themes` and `~/.themes`. `theme-switch.sh` alternates `Net/ThemeName` between `matugen-a` and `matugen-b` in `~/.config/xsettingsd/xsettingsd.conf`, sends `SIGHUP` to `xsettingsd`, and syncs `gsettings` + `gtk-{3.0,4.0}/settings.ini`.
- **Anki Live Hot-Reload:** The custom `matugen` add-on (`config/anki/addons21/matugen/`) hooks Anki's Qt style init and webview content injection, and uses `QFileSystemWatcher` on `~/.cache/matugen/anki-reload` (touched by `theme-switch.sh`) to repaint open Anki windows live.
- **Yazi Default Editor & Individual-File Symlinks:** Because `/etc/set-environment` exports `EDITOR="nano"` (and `home.nix`'s `programs.neovim.defaultEditor = true` is inactive without `programs.neovim.enable = true`), `config/yazi/yazi.toml` overrides only `[opener].edit` to `nvim %s` (`block = true`, `for = "unix"`), taking effect immediately in running X11 sessions without requiring a relogin. `~/.config/yazi/` **must remain a real directory** with individual file symlinks (`keymap.toml`, `yazi.toml`, `theme.toml`) — never a directory symlink to `config/yazi/`, which causes Home Manager to write symlinks into the repo and trigger `os error 40` circular symlink loops.

### Files Changed (Still Active)
- **`config/matugen/config.toml`:** Core `[config]` block (`version_check = false`, `fallback_color = "#7aa2f7"`, `source_color_index = 0`, `caching = false`) and Material You desktop/app templates (`sddm`, `dunst`, `rofi`, `oxwm`, `firefox`, `Obsidian`, `anki_qt`, `anki_webview`, `qt5ct`, `qt6ct`, `pcmanfm_qt`, `gtk`).
- **Desktop & App Templates (`config/matugen/templates/`):** `silent.conf`, `dunstrc`, `rofi-colors.rasi`, `colors.lua`, `firefox_websites.css`, `obsidian-minimal-matugen-colors.css`, `anki-qt.qss`, `anki-webview.css`, `qt5ct-colors.conf`, `qt6ct-colors.conf`, `pcmanfm-qt.qss`, `colors-gtk.css`.
- **App Configs & Add-ons:**
  - `config/dunst/dunstrc.d/10-matugen.conf` → `~/.cache/matugen/dunstrc` (replaced `10-pywal.conf`).
  - `config/rofi/matugen.rasi` & `config/rofi/config.rasi` (`@theme "matugen.rasi"`, replaced `pywal.rasi`).
  - `config/oxwm/config.lua` (prepends `~/.cache/matugen/?.lua` to `package.path` with `tokyonight` fallback).
  - `config/dusky_sites/{youtube.css,music.youtube.com.css,github.css}` (custom MatugenFox site stylesheets).
  - `config/anki/addons21/matugen/{__init__.py,manifest.json}` (replaced `addons21/pywal/`).
  - `config/pcmanfm-qt/default/settings.conf` & `config/gtk-{3.0,4.0}/settings.ini`.
  - `config/yazi/yazi.toml` (`[opener].edit` → `nvim %s`) & `config/yazi/keymap.toml` (`g w` → `~/nixos-dotfiles/walls`, `g m` → `theme-switch.sh %s --orphan`).
  - Deleted legacy `pywal` files (`config/wal/`, `config/anki/addons21/pywal/`, `config/dunst/dunstrc.d/10-pywal.conf`, `config/rofi/pywal.rasi`).
- **`configuration.nix`:** `silentSDDMTheme` symlinks to `/var/cache/matugen-sddm/`, `systemd.tmpfiles.rules` + activation seeding for `/var/cache/matugen-sddm`, and `QT_QPA_PLATFORMTHEME="qt5ct"`.
- **`home.nix`:** `pkgs.matugen`, `matugenfox-src`/`matugenfox-native` + Firefox `policies.json` (`matugenfox@ubaid.com` force-installed, `pywalfox@frewacom.org` blocked), `qt` (`qtct` + Fusion + `matugen.conf`), `pcmanfm-qt` `symlinkJoin` wrapper, `services.xsettingsd` + `matugen-a`/`matugen-b` GTK themes, Anki add-on symlink, `dusky_sites` + `matugen` + individual `yazi/{keymap,yazi,theme}.toml` symlinks.
- **`scripts/theme-switch.sh`:** Core Matugen v4.2.0 CLI orchestration (`MATUGEN_SCHEME="scheme-fidelity"`), SilentSDDM cache copy, Xresources/st reload, `.dunst-wrapped`-aware `dunstctl reload`, `oxwm` `super+shift+r` hot-reload, Anki reload touch, `.pcmanfm-qt-wra`-aware PCManFM-Qt restart, and `matugen-a`/`matugen-b` `xsettingsd`/`gsettings` GTK toggle.

---

## Part 2: Shell & Terminal Programs — Regular Material You Matugen (`1f5fce4`)

### Design Philosophy
- **True Material You Surfaces + Semantically Accurate ANSI Hues:** Pure `base16` palettes often produce muddy or unreadable terminal colors (e.g., green diffs looking beige). Mapping `surface`/`on_surface`/`on_surface_variant`/`outline` to background, foreground, and grayscale slots makes `st` blend seamlessly with the desktop, while `[config.custom_colors]` with `blend = true` harmonizes OneDark-inspired chromatic hues (`#e06c75`, `#98c379`, `#e5c07b`, `#61afef`, `#c678dd`, `#56b6c2`) with the active wallpaper without sacrificing semantic legibility.
- **`matugen 4.2.0` `auto_lightness` Convention:** In dark mode, positive `auto_lightness` deepens/darkens colors (`auto_lightness: 15` for normal ANSI `1–6`, `auto_lightness: 5` for bright ANSI `9–14`).
- **Terminal Transparency & `st` OSC Compatibility:** `st` has `ALPHA_PATCH=1` (`alpha=0.90`) and `XRESOURCES_RELOAD_PATCH=1` (`SIGUSR1`), and its OSC handler only accepts codes `0, 1, 2, 4, 8, 10, 11, 12, 52, 104, 110, 111, 112`. Keeping `sequences` single-line and omitting unsupported OSC codes (`13, 17, 19, 708`) eliminates `erresc` stderr noise. `btop` keeps `theme[main_bg]=""` and Neovim keeps `make_transparent()` so `st` transparency shines through.
- **Neovim `lualine` Load Order:** `after/plugin/colors.lua` runs before `after/plugin/one-liners.lua`. Calling `lualine.setup({ options = { theme = "auto" } })` overwrote `matugen.nvim`'s `lualine_*` highlights; re-applying `vim.cmd.colorscheme("matugen")` silently after `lualine.setup(...)` restores `matugen.nvim` highlights without triggering a startup reload notification.

### Files Changed
- **`config/matugen/config.toml`:** Removed the `base16` section; added `[config.custom_colors]` (`red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, all `blend = true`); registered regular Material You templates for `xresources`, `sequences`, `neovim`, `neovim_term`, `btop`, `yazi`, `fzf`, `bat`, `alacritty`, and `qylock` (replacing `lock`).
- **`config/matugen/templates/sequences` & `config/matugen/templates/colors.Xresources`:** Adapted from `InioX/matugen-themes` `terminal-sequences` using Material You grayscale tokens + blended `custom_colors` (`auto_lightness: 15` / `5`), single-line ESC sequences compatible with `st`.
- **`config/matugen/templates/btop.theme`:** Adapted from `InioX/matugen-themes` using regular Material You tokens with `theme[main_bg]=""`.
- **`config/matugen/templates/yazi-theme.toml`:** Adapted from `InioX/matugen-themes` to Yazi `26.8.15` schema (`**/` MIME globs, `[app]`, `[indicator]`, `[confirm]`, `[spot]`, `[icon]`) with all hardcoded Catppuccin hexes replaced by Matugen tokens.
- **`config/matugen/templates/fzf-colors.sh`:** Exports `FZF_DEFAULT_OPTS` using Material You tokens.
- **`config/matugen/templates/matugen-bat.tmTheme` & `config/bat/config`:** Material You + blended `custom_colors` TextMate theme for `bat` (`--theme="Matugen"`).
- **`config/matugen/templates/alacritty-colors.toml` & `config/alacritty/alacritty.toml`:** Imports `~/.cache/matugen/alacritty-colors.toml` instead of static TokyoNight colors.
- **Neovim (`config/nvim/lua/plugin-list.lua`, `config/nvim/after/plugin/colors.lua`, `config/nvim/after/plugin/one-liners.lua`, `config/matugen/templates/nvim-colors.json`, `config/matugen/templates/colors-nvim-term.lua`):** Replaced custom Base16 colorscheme (deleted `config/nvim/colors/matugen.lua` and `config/matugen/templates/colors-nvim.lua`) with `Senal-D-A-Gunaratna/matugen.nvim`, preserving `make_transparent()`, adding `apply_terminal_colors()` for `:Flterm`, and keeping `lualine` highlights intact.
- **`home.nix`:** Updated `programs.bash.initExtra` (`PS1` uses dynamic ANSI `1;32`/`1;34` instead of hardcoded 256-color indices, sources `~/.cache/matugen/fzf-colors.sh`, exports `BAT_THEME="Matugen"`), and symlinked `bat/config` and `bat/themes/Matugen.tmTheme` → `~/.cache/matugen/bat.tmTheme`.
- **`scripts/theme-switch.sh`:** Added live `SIGUSR2` reload for `btop`/`.btop-wrapped`, `bat cache --build`, and `SIGUSR1` reload for `nvim`/`.nvim-wrapped`.

---

## Part 3: Matugen-Themed `qylock` Screenlock + OLED `xscreensaver` (`c945fe9`)

### Design Philosophy
- **Lean Nix Derivation Over Full Upstream Module:** Upstream `Darkkal44/qylock`'s NixOS module copies 40+ themes (including large video assets) into `/nix/store` and hardcodes colors + `bg.png` in `themes/material-you-dark/Main.qml`. Building a custom `qylockMatugen` derivation from `inputs.qylock` copies only `quickshell-lockscreen/` and `themes/material-you-dark/` (preserving the upstream Google Sans variable font, layout, SVGs, and animations) while cleanly patching `SddmShim.qml` and `lock_shell.qml` for NixOS + X11.
- **Zero-Rebuild Dynamic Wallpaper & Colors:** `config/qylock/Main.qml` synchronously reads `file://$HOME/.cache/matugen/qylock-colors.json` via `XMLHttpRequest` (`QML_XHR_ALLOW_FILE_READ=1`) before the first frame renders (avoiding any default-color flash), renders the raw active wallpaper (`PreserveAspectCrop`) behind a `0.28` opacity `scrim` for legibility on bright wallpapers, and maps all 14 Material You Dark tokens with upstream dark hexes as fallbacks.
- **Preserved Entrypoints & `SilentSDDM`:** Keeping `/run/current-system/sw/bin/oxwm-lock` as the single entrypoint preserves `Super+Shift+L` (`config/oxwm/keybinds/keys.lua`), `xidlehook` + `oxwm-lock-warn` (`config/oxwm/modules/screen-lock.lua`), and `programs.xss-lock` (`configuration.nix`) with zero changes. `SilentSDDM` remains untouched for SDDM.
- **OLED Burn-In Protection with Instant Teardown:** While `qylock-lock` runs, `oxwm-lock` spawns a background watcher using two tiny C X11 helpers (`oxwm-wait-input` and `oxwm-oled-saver-win`). After 60s of continuous inactivity, `oxwm-oled-saver-win` opens a fullscreen black override-redirect X11 window over `qylock` and runs `${pkgs.xsecurelock}/libexec/xsecurelock/saver_xscreensaver` (honoring `~/.xscreensaver`, e.g. `mode: one`, `selected: 245`). Any mouse move or keypress immediately kills the saver process group to reveal `qylock`. Both `qylock-lock` and `oxwm-wait-input` are run with `& wait` so `SIGTERM` / unlock teardown completes in ~14 ms with zero lingering processes.
- **X11 Hardening & Tradeoff:** `lock_shell.qml`'s `x11Loader` is patched with `Qt.X11BypassWindowManagerHint` (override-redirect so `oxwm` cannot tile, cover with its bar, or close it with `Super+Q`), explicit per-monitor geometry, and `requestActivate()`. Because Quickshell does not hold an active X11 `XGrabKeyboard` grab, root-window WM keybinds remain an inherent X11 Quickshell limitation.
- **Faster `themeswitch`:** Because `qylock` uses the raw active wallpaper directly, the old ImageMagick dual-Kawase `generate_frosted_lock_wallpaper` pass was removed from `scripts/theme-switch.sh`.

### Files Changed
- **`flake.nix` & `flake.lock`:** Added `qylock` (`github:Darkkal44/qylock`, `inputs.nixpkgs.follows = "nixpkgs"`).
- **`config/matugen/templates/qylock-colors.json`:** Generates `~/.cache/matugen/qylock-colors.json` with `wallpaper` (`{{ image }}`) and 14 Material You Dark tokens (`surface`, `surface_container_*`, `primary`, `primary_container`, `secondary_container`, `on_surface`, `on_surface_variant`, `outline`, `error`, `scrim`). Deleted legacy `config/matugen/templates/colors-lock.sh`.
- **`config/qylock/Main.qml`:** Matugen-enabled adaptation of upstream `themes/material-you-dark/Main.qml`.
- **`configuration.nix`:**
  - Added `qylockMatugen` derivation (patching `SddmShim.qml` for `suspend()`, NixOS `/run/current-system/sw/share/xsessions` so Session displays `OXWM`, and `config: "qylock"` on `PamContext`; patching `lock_shell.qml` for X11 override-redirect + per-monitor geometry + focus; wrapping `qylock-lock` with Qt6 QML paths, `QT_QPA_PLATFORM=xcb`, and `QML_XHR_ALLOW_FILE_READ=1`).
  - Added `oxwm-lock-helpers` (`oxwm-oled-saver-win` + `oxwm-wait-input`) and replaced `oxwm-lock` with the `qylock-lock` + 60s OLED `xscreensaver` watcher (plus single-instance guard).
  - Removed obsolete `xsecurelock` locker definitions (`lockImage`, `xsecurelockSettings`, `exportXsecurelockEnv`, `oxwm-set-win-bg`, `oxwm-saver-hybrid`), replaced `security.pam.services.xsecurelock` with `security.pam.services.qylock = {};`, and updated `picom` `fade-exclude` to `quickshell` / `Quickshell`.
- **`scripts/theme-switch.sh`:** Removed `FROST_*`, `generate_frosted_lock_wallpaper()`, `--frost-only`, and `FROST_PID`.

---

## Part 4: PAM Password-Gated `POWER` & `REBOOT` Protection (`a117aeb`)

### Design Philosophy
- **Keep Tiles Useful Without Allowing Drive-By Reboots:** Rather than removing the `POWER` and `REBOOT` tiles, clicking either sets a `pendingAction` state (`"powerOff"` or `"reboot"`), visually highlights the tile (`primary` border, `primary_container` icon circle, `CONFIRM PWD` subtitle), updates the password placeholder (`PASSWORD TO SHUT DOWN` / `PASSWORD TO REBOOT`) and action button (`SHUT DOWN →` / `REBOOT →`), and focuses the password input. Pressing `Escape` (or clicking the tile again) cancels back to normal `UNLOCK` mode.
- **No Desktop Exposure During Shutdown/Reboot:** `SddmShim.qml` executes `powerOff()` / `reboot()` inside `PamContext.onCompleted` only on `PamResult.Success` and intentionally does **not** emit `loginSucceeded()`, keeping the lockscreen covering the desktop while the machine shuts down or reboots. Failed PAM attempts shake the card with `ACCESS DENIED` and refuse the action.
- **Sleep Remains Fast:** `SLEEP (SUSPEND)` stays immediate without a password because waking from suspend returns directly to the lockscreen.
- **Hardware Reality:** On the Lenovo Legion 15IAX11, holding the physical power button for ~10 seconds triggers a motherboard Embedded Controller (EC) hard power-off regardless of OS configuration.

### Files Changed
- **`config/qylock/Main.qml`:** Added `pendingAction`, visual tile selection states, dynamic prompt/button labels, `Escape` cancellation, and `sddm.loginWithAction(...)` submission.
- **`configuration.nix`:** Extended the `SddmShim.qml` patch inside `qylockMatugen` with `loginWithAction(user, password, sessionIndex, action)` and `pam.pendingAction` handling in `PamContext.onCompleted`.

---

## Part 5: Firefox Tab Notifications — Click-to-Focus & Markdown Formatting

### Design Philosophy
- **Two-Part Focus Chain (`oxwm` + Firefox):** Previously, Dunst mapped `mouse_left_click = close_current`, so clicking a notification dismissed it without invoking Firefox's `"default"` D-Bus action. Furthermore, `oxwm` hides windows on inactive tags off-screen (`X < 0`) and ignores cross-tag `_NET_ACTIVE_WINDOW` client messages. Switching `mouse_left_click` to `do_action, close_current` emits `ActionInvoked(id, "default")` (so Firefox switches to the exact originating tab), while a small C hook in `dunstPatched` spawns `oxwm-focus-firefox` asynchronously to switch `oxwm` to tag 1 (`Super+1`) whenever Firefox is off-screen (`X < 0`) and ensure Firefox receives focus.
- **Native Markdown-to-Pango in Dunst (No D-Bus Proxy):** Rather than running a fragile D-Bus proxy or replacing notifications via `dunstify -r` (which would destroy Firefox's `default` action), `dunstPatched` converts Markdown (`**bold**`, `*italic*`, `***bold italic***`, word-boundary `__bold__`/`_italic_`, `` `code` ``, fenced code blocks, `~~strike~~`, `# Headings`, `* `/` - ` bullets → `• `, `[label](url)` → `<u>label</u>`, backslash escapes) directly in `src/markup.c` while preserving existing Pango/XML tags, snake_case identifiers, and math expressions (`2 * 3 * 4`). Every converted string is validated with `pango_parse_markup()`, falling back to the original text if Pango ever rejects it.
- **Consistent Matugen Dunst Startup:** Updated `oxwm.autostart` to launch `dunst -config ~/.cache/matugen/dunstrc` when available (instead of starting with the static fallback until `themeswitch` runs), and synced both `config/matugen/templates/dunstrc` and `config/dunst/dunstrc`.

### Files Changed
- **`config/dunst/dunst-firefox-markdown.patch`:** Unified diff against Dunst `1.13.2` adding `markup_markdown_to_pango()` in `src/markup.c`/`src/markup.h`, applying it to `MARKUP_FULL` bodies and summaries, and invoking `oxwm-focus-firefox` from `notification_do_action()` in `src/notification.c` for Firefox notifications.
- **`configuration.nix`:** Added `oxwm-focus-firefox` (`writeShellApplication`) and `dunstPatched` (`pkgs.dunst.overrideAttrs`), replacing `pkgs.dunst` in `environment.systemPackages`.
- **`config/matugen/templates/dunstrc` & `config/dunst/dunstrc`:** Set `mouse_left_click = do_action, close_current`, `mouse_middle_click = close_current`, fixed `/usr/bin/` paths in the fallback `dunstrc`, and added a `[firefox]` rule (`appname = Firefox`, `timeout = 6`).
- **`config/oxwm/config.lua`:** Updated `oxwm.autostart` to launch `dunst` with `~/.cache/matugen/dunstrc` if present.

---

## Part 6: Lenovo Legion 15IAX11 Native OpenRGB, Matugen Sync & Screen-Brightness Tracking

### Design Philosophy
- **Native Lenovo Spectrum (`0xFF89` / Report ID `0x07`) Over HID LampArray (`0x59`):** The Legion 15IAX11's `048d:c615` (`ITE Device(8258)`) exposes both USB HID LampArray (`Usage Page 0x59`, `LampCount=1`, 24-bit RGB) and Lenovo Spectrum (`Usage Page 0xFF89`, `Usage 0x07`, 960-byte Feature Report, Gen 10+ payload length format, 1 LED at ID `0x0001`). Using Lenovo Spectrum via OpenRGB's `LenovoUSBController_Gen7_8` writes directly into the keyboard's onboard hardware profiles (`Profile 1–6`), so **`Fn + Space`** profile cycling and **`Fn + Up/Down`** brightness keys continue to work natively (whereas HID LampArray overrides firmware control while active).
- **Minimal OpenRGB Patch (`openrgbPatched`):** Rather than replacing OpenRGB with a separate daemon, patching `pkgs.openrgb` (`1.0rc3.1`) via `overrideAttrs` registers `LEGION_5GEN11_1ZONE` (`0xC615`) in `LenovoUSBController_Gen7_8` with a clean `Keyboard (1-zone)` zone (`ZONE_TYPE_SINGLE`, LED `0x0001`) and excludes per-key-only effects (`Rain`, `Type Lighting`).
- **Vivid LED Color Transform (Fixing Washed-Out White Pastels):** Material You dark-mode `primary` tokens are Tone 80 pastels (high lightness, low saturation — e.g. `#ccc6b7`), which wash out to white on linear physical RGB LEDs. `oxwm-rgb-sync` converts `primary` from RGB → HSV in `gawk`, preserves the exact wallpaper hue, boosts saturation (`max(S * 1.8, 0.80)`, keeping pure monochrome `S <= 0.02` as `#FFFFFF`) at `V = 1.0`, and applies LED gamma (`1.8`) so keyboard colors match the wallpaper hue vividly.
- **Screen-Brightness Tracking & Battery Power Conservation:** The controller supports 10 hardware brightness levels (`0–9`). `oxwm-rgb-sync` reads the active `eDP*` `xrandr --verbose --current` brightness (`0–100%`, clamping non-zero values `< 12%` to `12%` so level `1` stays visible while the screen is on) and applies it via `openrgb -d 0 -b <pct>` (preserving the active mode). `brightness-notify` invokes `oxwm-rgb-sync brightness "$bright"` asynchronously so brightness keys stay instantaneous. On battery, `battery-mode` runs `oxwm-rgb-sync off` (`-b 0`) before stopping `openrgb.service`, and `oxwm-rgb-sync` no-ops on battery so `themeswitch` and brightness keys never waste power; `ac-mode` restarts `openrgb.service` and runs `oxwm-rgb-sync sync --restore`.

### Files Changed
- **`config/openrgb/legion-15iax11-c615.patch`:** Clean `diff -ruN` patch against OpenRGB `1.0rc3.1` adding `LEGION_5GEN11_1ZONE` (`0xC615`) to `LenovoDevices.h`, `LenovoUSBControllerDetect.cpp`, `LenovoUSBController_Gen7_8.cpp`, and `RGBController_Lenovo_Gen7_8.cpp`.
- **`configuration.nix`:**
  - Added `openrgbPatched` (`pkgs.openrgb.overrideAttrs`) and wired it into `services.hardware.openrgb.package` and `environment.systemPackages`.
  - Added `oxwm-rgb-sync` (`writeShellApplication`) supporting `sync`, `off`, and `brightness [0-100]`.
  - Updated `systemd.services.battery-mode` to turn RGB off before stopping `openrgb.service`, and `systemd.services.ac-mode` to restart `openrgb.service` and restore Matugen color + screen brightness.
- **`scripts/theme-switch.sh`:** Invokes `oxwm-rgb-sync sync` to sync the keyboard backlight on theme switches (no-ops on battery).
- **`scripts/notify.nix`:** Updated `brightness-notify` to call `/run/current-system/sw/bin/oxwm-rgb-sync brightness "$bright" &` whenever screen brightness changes.

---

## Part 7: OXWM Volume Block, Muted Notification & Live Yazi Theme Reload

### Design Philosophy
- **Minimal-Overhead Volume Polling (`volume-status.sh`):** `scripts/volume-status.sh` makes a single `wpctl get-volume @DEFAULT_AUDIO_SINK@` call and outputs ` <vol>` (`U+EFCF`) when unmuted or ` <vol>` (`U+EEE8`) when `[MUTED]`. It runs at `interval = 1` in `config/oxwm/config.lua` because OXWM's bar scheduler only supports integer-second polling (`interval = 0` disables updates) and has no signal-based refresh.
- **Dunst Category Rule for Non-Bold `(muted)`:** Because Dunst escapes Pango markup inside `%s`, putting `<span>` tags in the summary string fails. Instead, `volume-notify` passes `-c volume-muted` when `[MUTED]` (and `-c volume` otherwise), and Dunst matches `category = volume-muted` with `format = "<b>%s</b> (muted)\n%b"`, keeping **Volume** bold and `(muted)` regular weight while stacking via `stack_tag = volume`.
- **Three-Part Yazi Live Theme Reload & Reboot Fix:**
  1. **Always `xrdb -merge` on OXWM Startup:** `oxwm.autostart` previously skipped `xrdb -merge ~/.cache/matugen/colors.Xresources` whenever `colors.lua` already existed, causing `Super+E` (`st -e ...`, which bypasses `~/.bashrc` and `sequences`) to fall back to `st`'s compiled-in Tokyo Night colors after reboot. Now `oxwm.autostart` unconditionally merges `colors.Xresources`.
  2. **Graceful `SIGUSR1` Restart Wrapper (`yazi-matugen.sh`):** Because Yazi `26.8.15` only reads `theme.toml` at startup, `scripts/yazi-matugen.sh` registers each instance PID in `$XDG_RUNTIME_DIR/yazi-matugen/`, passes `--client-id` and `--cwd-file`, traps `SIGUSR1` (sent by `theme-switch.sh`) to emit `ya emit-to <id> quit`, and immediately reopens Yazi in the saved directory with the new Material You theme (passing through non-interactive / `--chooser-file` / `--version` invocations untouched).
  3. **Themed Code Previews:** `config/matugen/templates/yazi-theme.toml` sets `syntect_theme = "~/.cache/matugen/bat.tmTheme"` under `[mgr]` so Yazi's file preview pane matches the active Material You palette.

### Files Changed
- **`scripts/volume-status.sh` & `config/oxwm/config.lua`:** Added `volume-status.sh` and wired it into `oxwm.bar.block.shell` (`interval = 1`, `format = "{}"`).
- **`scripts/notify.nix`, `config/dunst/dunstrc`, `config/matugen/templates/dunstrc`:** Unified `volume-notify` onto `dunstify -c volume|volume-muted` and added the `[volume_muted]` Dunst rule (`format = "<b>%s</b> (muted)\n%b"`).
- **`scripts/yazi-matugen.sh`, `scripts/theme-switch.sh`, `config/oxwm/keybinds/keys.lua`, `config/oxwm/config.lua`, `home.nix`, `config/matugen/templates/yazi-theme.toml`:** Added `yazi-matugen.sh` live reload wrapper, `SIGUSR1` broadcast in `theme-switch.sh`, `Super+E` binding (`keys.lua`), `yazi` bash alias (`home.nix`), unconditional `xrdb -merge` on startup (`config.lua`), and `syntect_theme = "~/.cache/matugen/bat.tmTheme"` (`yazi-theme.toml`).

---

## Part 8: NixOS `nrs` Evaluation Warning Cleanup

### Design Philosophy
- Keep `nixos-rebuild switch` (`nrs`) evaluation completely free of Nixpkgs deprecation warnings by using current attribute paths.

### Files Changed
- **`home.nix`:** Replaced `pkgs.system` with `pkgs.stdenv.hostPlatform.system` for `inputs.antigravity-nix`.
- **`configuration.nix`:** Replaced `pkgs.xorg.libX11` with `pkgs.libx11` in `oxwm-lock-helpers`.

---

## Part 9: `btop` Dual-GPU Monitoring (NVIDIA RTX 5060 + Intel iGPU)

### Design Philosophy & Decisions
- **`pkgs.btop-cuda` for NVIDIA NVML (`RUNPATH`, Zero CUDA Toolkit Overhead):** Nixpkgs's default `pkgs.btop` builds with `cudaSupport = false`, omitting `autoAddDriverRunpath` so `/run/opengl-driver/lib` is absent from ELF `DT_RUNPATH` and `dlopen("libnvidia-ml.so.1")` fails silently (logged only at `INFO`, below `btop.conf`'s `log_level = "WARNING"`). Switching to `pkgs.btop-cuda` does **not** pull in the CUDA toolkit—it only runs `autoAddDriverRunpath` to bake `/run/opengl-driver/lib` into `DT_RUNPATH`.
- **Least-Privilege `security.wrappers.btop` (`cap_perfmon+ep`) for Intel `i915` PMU:** `btop`'s Intel GPU backend (`PCI:0:2:0`, `8086:7D67`, `i915` + `/sys/bus/event_source/devices/power/events/energy-gpu`) uses system-wide `perf_event_open(..., pid=-1, ...)`, which fails with `EACCES` (`WARNING: Intel GPU: Failed to initialize PMU`) under `kernel.perf_event_paranoid = 2`. Wrapping `${pkgs.btop-cuda}/bin/btop` via `security.wrappers.btop` (`owner = "root"`, `group = "wheel"`, `permissions = "u+rx,g+x"`, `capabilities = "cap_perfmon+ep"`) grants ambient `CAP_PERFMON` for Intel GPU utilization, clocks, and GPU RAPL watts without weakening system-wide `perf_event_paranoid` or granting `cap_dac_read_search` / `setuid`.
- **Compatibility with `security.wrappers`, `rofi`, and Matugen Live Reload:**
  - `${pkgs.btop-cuda}/bin/btop` is a pure ELF binary with `/run/opengl-driver/lib` in `DT_RUNPATH` (not `LD_LIBRARY_PATH`), so it passes NixOS's `ensure-wrapper-integrity` ELF check and still loads `libnvidia-ml.so.1` after NixOS's `wrapper.c` strips insecure env vars.
  - `/run/wrappers/bin` precedes user/system bin dirs in `PATH` and `btop.desktop` uses `Exec=btop`, so both shells and `rofi` launch `/run/wrappers/bin/btop`.
  - Using `capabilities` instead of `setuid` keeps the running `btop` process owned by `smalldog` with `/proc/<pid>/comm` = `btop`, preserving `scripts/theme-switch.sh`'s unprivileged `pkill -USR2 -x btop` live theme reload.
  - `btop = "btop"` in `home.nix`'s `configs` symlink map stays unchanged because `btop-cuda` still reads `~/.config/btop/btop.conf`.
- **NVIDIA PRIME Offload / D3cold Behavior:** Because `"nvidia"` is in `shown_gpus`, `btop` calls `nvmlInit()` and wakes the RTX 5060 (`0000:01:00.0`) from `suspended` (D3cold) while open (~6.4 W idle), and the kernel driver automatically returns it to `suspended` shortly after `btop` exits.

### Files Changed
- **`home.nix`:** Removed `btop` from `home.packages` (kept `btop = "btop"` in `configs`).
- **`configuration.nix`:** Added `btop-cuda` to `environment.systemPackages` and added `security.wrappers.btop` (`root:wheel`, `u+rx,g+x`, `cap_perfmon+ep`, `source = "${pkgs.btop-cuda}/bin/btop"`).
- **`config/btop/btop.conf`:** Updated `shown_boxes = "cpu mem net proc gpu0 gpu1"` and cleared `custom_gpu_name0 = ""` so actual detected GPU names display cleanly.

---

## Quick Reference & Token-Saving Gotchas for Future Sessions

- **Do Not Re-Investigate Known OXWM Limits:** OXWM (`src/bar/bar.zig`, `src/bar/blocks/blocks.zig`) cannot natively center a bar block, treats `interval = 0` as disabled, has no `SIGRTMIN+N`/IPC block refresh, and has `interval = 1` as its fastest polling rate.
- **Never Finalize `st-flexipatch`:** Keep `config/st/` as `st-flexipatch` (do not run `flexipatch-finalizer`). Use `nix develop .#suckless` for manual builds; `st` has `ALPHA_PATCH=1` (`alpha = 0.90`), `XRESOURCES_RELOAD_PATCH=1`, and `SIXEL_PATCH=1` (`imlib2`).
- **Changing the Matugen Scheme:** Edit `MATUGEN_SCHEME="scheme-fidelity"` at line 12 of `scripts/theme-switch.sh` (or test ad hoc with `themeswitch -t <scheme> <wall>`).
- **NixOS Wrapper Process Names:** Always check both unwrapped and wrapped `comm` names in `pgrep -x`/`pkill -x` (`.dunst-wrapped`, `.pcmanfm-qt-wra`, `.btop-wrapped`, `.nvim-wrapped`).
- **Yazi Config & Live Reload Rules:**
  - Keep `~/.config/yazi/` as a **real directory** containing individual file symlinks (`keymap.toml`, `yazi.toml`, `theme.toml`); never symlink `~/.config/yazi` itself to `config/yazi/` or Home Manager will create circular symlinks (`os error 40`).
  - Interactive Yazi runs through `scripts/yazi-matugen.sh` (`Super+E` and `yazi` bash alias) so `theme-switch.sh` can `SIGUSR1`-reload it in place without losing cwd.
- **Dunst Summary Formatting:** Dunst escapes Pango markup inside `%s`; use `category` matching + custom `format` rules (as in `[volume_muted]`) instead of embedding markup in summaries.
- **Idle Lock (`xidlehook`):** Keep `xidlehook` invoked directly in `config/oxwm/modules/screen-lock.lua` (never wrap in `sh -c "pkill ..."`). Idle chain: 4m30s `oxwm-lock-warn` → 5m `oxwm-lock` (`qylock`) → 60s `xscreensaver` via `oxwm-wait-input` (never use `xsecurelock`'s `until_nonidle`, which defaults to 7s).
- **App Theme Output Paths:**
  - MatugenFox CSS: `~/.config/matugen/generated/firefox_websites.css` (polled every 2s) + site templates in `~/.config/dusky_sites/`.
  - Obsidian CSS snippet: `/home/smalldog/Documents/2026-2027 Term 1/.obsidian/snippets/matugen-colors.css` (enable `matugen-colors` in Obsidian Appearance → CSS snippets).
  - SilentSDDM cache: `/var/cache/matugen-sddm/{silent.conf,wallpaper.png}` (owned by `smalldog:users`, no `sudo` needed; `silent.conf` must include all QML layout properties).
  - Qt / PCManFM-Qt: `~/.config/qt{5,6}ct/colors/matugen.conf` + `~/.cache/matugen/pcmanfm-qt.qss` (injected by the `pcmanfm-qt` `symlinkJoin` wrapper in `home.nix`).
  - GTK 3/4 live reload: `matugen-a` ↔ `matugen-b` toggled in `~/.config/xsettingsd/xsettingsd.conf` (`SIGHUP` to `xsettingsd`).
  - Lockscreen colors & wallpaper: `~/.cache/matugen/qylock-colors.json` (generated by `matugen` from `config/matugen/templates/qylock-colors.json`).
- **Testing UI/Lockscreen Changes Safely:** Run `Xvfb :99 -screen 0 1280x800x24 +extension GLX -nolisten tcp` with `LIBGL_ALWAYS_SOFTWARE=1` (so `Qt5Compat.GraphicalEffects` `ColorOverlay` renders accurately) and `maim` / `xdotool` on `DISPLAY=:99`. Never lock or screenshot `DISPLAY=:0` while the user is active.
- **Testing `themeswitch` Headlessly:** Prefix with `DISPLAY=` (`DISPLAY= ~/nixos-dotfiles/scripts/theme-switch.sh <wall>`) to regenerate `~/.cache/matugen/*` without touching `feh`, `xrdb`, `dunst`, or `oxwm` on `:0`.
- **Keyboard RGB Hardware & CLI:** `048d:c615` (`ITE Device(8258)`, 1-zone Lenovo Spectrum via `openrgbPatched` / `openrgb.service`). Control manually with `openrgb` or `oxwm-rgb-sync {sync|off|brightness [0-100]}`.
- **`btop` Dual-GPU Setup:** Installed in `configuration.nix` (not `home.nix`) as `pkgs.btop-cuda` (for `/run/opengl-driver/lib` ELF `DT_RUNPATH` → NVIDIA NVML) + `security.wrappers.btop` (`cap_perfmon+ep`, `root:wheel` → Intel `i915` + `power` PMU). Never switch the wrapper to `setuid` (breaks unprivileged `pkill -USR2 -x btop` in `theme-switch.sh`), and keep `btop = "btop"` in `home.nix`'s `configs` symlink map.
