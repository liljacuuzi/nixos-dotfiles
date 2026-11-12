#!/usr/bin/env bash
set -e

# ==============================================================================
# FROSTED LOCKSCREEN SETTINGS (dual_kawase + frosted glass effect)
# Modify any of these values to tune how frosted your lockscreen looks!
# Changes take effect automatically the next time you press Super+Shift+L
# (or run `themeswitch` / `themeswitch --frost-only`).
# ==============================================================================
FROST_BLUR_STRENGTH="2.5"  # Blur sigma per Kawase pass (0.5 = crisp, 2.5 = medium frost, 6.0 = heavy blur)
FROST_DOWNSAMPLE="60"      # Kawase downsample % (10 = ultra-wide dreamy blur, 25 = balanced, 60 = very light)
FROST_WHITE_GLAZE="12"     # Milky white frosted glass sheen % (0 = none, 12 = frosted glass, 25 = icy white)
FROST_PYWAL_TINT="0"       # Pywal theme tint % (0 = original colors, 6 = subtle tint; >15 will darken the image)
FROST_GRAIN="0.11"         # Etched glass micro-grain (0 = smooth blur, 0.22 = frosted texture, 0.50 = sandblasted)

generate_frosted_lock_wallpaper() {
    local src_wall="$1"
    if [ ! -f "$src_wall" ] && [ -f "$HOME/.cache/wal/wal" ]; then
        src_wall="$(cat "$HOME/.cache/wal/wal")"
    fi
    if [ ! -f "$src_wall" ]; then
        src_wall="$HOME/nixos-dotfiles/walls/2560x1600p/tokyo-text.png"
    fi
    [ -f "$src_wall" ] || return 0
    command -v magick >/dev/null 2>&1 || return 0

    mkdir -p "$HOME/.cache/wal"
    local bg_hex="#1a1b26"
    if [ -f "$HOME/.cache/wal/colors.sh" ]; then
        bg_hex="$(grep -E "^background=" "$HOME/.cache/wal/colors.sh" | cut -d"'" -f2)"
    fi

    local sig="v2|${src_wall}|${FROST_BLUR_STRENGTH}|${FROST_DOWNSAMPLE}|${FROST_WHITE_GLAZE}|${FROST_PYWAL_TINT}|${FROST_GRAIN}|${bg_hex}"
    if [ -f "$HOME/.cache/wal/lock-wallpaper.png" ] && [ -f "$HOME/.cache/wal/lock-wallpaper.sig" ]; then
        if [ "$(cat "$HOME/.cache/wal/lock-wallpaper.sig" 2>/dev/null)" = "$sig" ]; then
            return 0
        fi
    fi

    # Dual-Kawase downsample -> etched grain -> upsample -> pywal tint -> milky frost glaze
    magick "$src_wall" \
        -resize 2560x1600^ -gravity center -extent 2560x1600 \
        -filter Triangle \
        -resize "${FROST_DOWNSAMPLE}%" -blur "0x${FROST_BLUR_STRENGTH}" \
        -resize 60% -blur "0x${FROST_BLUR_STRENGTH}" \
        -attenuate "$FROST_GRAIN" +noise Gaussian \
        -resize 166% -blur "0x1.2" \
        -resize 2560x1600! \
        -fill "${bg_hex:-#1a1b26}" -colorize "${FROST_PYWAL_TINT}%" \
        -fill "#ffffff" -colorize "${FROST_WHITE_GLAZE}%" \
        -define png:compression-level=1 \
        "$HOME/.cache/wal/lock-wallpaper.tmp.png" 2>/dev/null && \
    mv -f "$HOME/.cache/wal/lock-wallpaper.tmp.png" "$HOME/.cache/wal/lock-wallpaper.png" && \
    printf '%s' "$sig" > "$HOME/.cache/wal/lock-wallpaper.sig"
}

if [ "$1" = "--frost-only" ]; then
    generate_frosted_lock_wallpaper "$2"
    exit 0
fi

# Read from stdin if piped, otherwise use first argument
INPUT=""
if [ -n "$1" ]; then
    INPUT="$1"
elif [ ! -t 0 ]; then
    read -r INPUT
fi

# Expand tilde ~ if passed as raw string
INPUT="${INPUT/#\~/$HOME}"
INPUT="$(echo "$INPUT" | xargs)" # trim whitespace

# Default to currently active pywal wallpaper if no argument given, then fallback to tokyo-text.png
ACTIVE_WAL=""
if [ -f "$HOME/.cache/wal/wal" ]; then
    ACTIVE_WAL="$(cat "$HOME/.cache/wal/wal")"
fi
WALLPAPER="${INPUT:-${ACTIVE_WAL:-$HOME/nixos-dotfiles/walls/2560x1600p/tokyo-text.png}}"

# 1. Generate colors using pywal16
if [ "$1" = "--theme" ] && [ -n "$2" ]; then
    echo "==> Applying pywal theme: $2"
    wal --theme "$2" -q
elif [ -f "$WALLPAPER" ]; then
    echo "==> Generating palette from wallpaper: $WALLPAPER"
    wal -i "$WALLPAPER" -q
    if command -v feh >/dev/null 2>&1; then
        feh --bg-scale "$WALLPAPER"
    fi
else
    echo "Error: File '$WALLPAPER' not found."
    echo "Usage: $(basename "$0") </path/to/wallpaper.png | --theme <themename> | --frost-only>"
    echo "   or: echo /path/to/wallpaper.png | $(basename "$0")"
    exit 1
fi

# Resolve active wallpaper path from pywal cache if --theme was used
if [ ! -f "$WALLPAPER" ] && [ -f "$HOME/.cache/wal/wal" ]; then
    WALLPAPER="$(cat "$HOME/.cache/wal/wal")"
fi

echo "==> Generating dual_kawase frosted lockscreen wallpaper..."
generate_frosted_lock_wallpaper "$WALLPAPER" &

echo "==> Updating SilentSDDM theme..."
SDDM_WAL_DIR="/var/cache/wal-sddm"
if [ -d "$SDDM_WAL_DIR" ]; then
    if [ -f "$HOME/.cache/wal/silent.conf" ]; then
        cp -f "$HOME/.cache/wal/silent.conf" "$SDDM_WAL_DIR/silent.conf" 2>/dev/null || true
    fi
    if [ -f "$WALLPAPER" ]; then
        cp -f "$WALLPAPER" "$SDDM_WAL_DIR/wallpaper.png" 2>/dev/null || true
    fi
    chmod 644 "$SDDM_WAL_DIR"/* 2>/dev/null || true
fi

echo "==> Updating Xresources database..."
if [ -f "$HOME/.cache/wal/colors.Xresources" ]; then
    xrdb -merge "$HOME/.cache/wal/colors.Xresources"
fi

echo "==> Updating st terminals..."
# Live OSC escape sequence injection into all open ptys
for tty in /dev/pts/[0-9]*; do
    if [ -w "$tty" ]; then
        cat "$HOME/.cache/wal/sequences" > "$tty" 2>/dev/null || true
    fi
done

# Signal st instances with XRESOURCES_RELOAD_PATCH
pkill -USR1 -x st 2>/dev/null || true

echo "==> Updating dunst..."
if command -v dunstctl >/dev/null 2>&1; then
    dunstctl reload "$HOME/.cache/wal/dunstrc" 2>/dev/null || true
fi
if ! pgrep -f dunst >/dev/null 2>&1; then
    if [ -f "$HOME/.cache/wal/dunstrc" ]; then
        dunst -config "$HOME/.cache/wal/dunstrc" >/dev/null 2>&1 &
    else
        dunst >/dev/null 2>&1 &
    fi
fi

echo "==> Hot-reloading oxwm..."
if command -v xdotool >/dev/null 2>&1; then
    xdotool key super+shift+r 2>/dev/null || true
fi

echo "==> Updating running Neovim instances..."
for sock in $(find "${XDG_RUNTIME_DIR:-/tmp}" -name "nvim*.0" -o -name "nvim*" 2>/dev/null); do
    if [ -S "$sock" ]; then
        nvim --server "$sock" --remote-send "<Esc>:colorscheme pywal<CR>" 2>/dev/null || true
    fi
done

echo "==> Updating Firefox..."
if command -v pywalfox >/dev/null 2>&1; then
    pywalfox update >/dev/null 2>&1 || true
fi

echo "==> Updating Anki..."
touch "$HOME/.cache/wal/anki-reload" 2>/dev/null || true

echo "==> Updating PCManFM-Qt..."
if pgrep -f "pcmanfm-qt" >/dev/null 2>&1; then
    pcmanfm-qt -q 2>/dev/null || true
    for i in $(seq 1 10); do
        if ! pgrep -f "pcmanfm-qt" >/dev/null 2>&1; then
            break
        fi
        sleep 0.05
    done
    setsid pcmanfm-qt >/dev/null 2>&1 &
fi

echo "==> Updating GTK apps..."
XSETTINGS_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
# Toggle between wal-a and wal-b so GTK detects a theme change and reloads CSS live
if [ -f "$XSETTINGS_CONF" ] && grep -q 'Net/ThemeName "wal-a"' "$XSETTINGS_CONF"; then
    NEXT_THEME="wal-b"
else
    NEXT_THEME="wal-a"
fi

mkdir -p "$HOME/.config/xsettingsd"
cat << EOF > "$XSETTINGS_CONF"
Net/ThemeName "$NEXT_THEME"
Net/IconThemeName "Papirus-Dark"
Gtk/CursorThemeName "Adwaita"
EOF

# Broadcast SIGHUP to xsettingsd
pkill -HUP -x xsettingsd 2>/dev/null || true

# Update GSettings / dconf for apps watching GNOME settings
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$NEXT_THEME" 2>/dev/null || true
fi

# Keep settings.ini in sync for future app launches
for ver in gtk-3.0 gtk-4.0; do
    if [ -f "$HOME/.config/$ver/settings.ini" ]; then
        sed -i "s/gtk-theme-name = .*/gtk-theme-name = $NEXT_THEME/" "$HOME/.config/$ver/settings.ini" 2>/dev/null || true
    fi
done

echo "==> Theme switch complete!"
