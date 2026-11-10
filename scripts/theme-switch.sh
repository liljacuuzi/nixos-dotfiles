#!/usr/bin/env bash
set -e

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

# Fallback to default wallpaper if input is empty
WALLPAPER="${INPUT:-$HOME/nixos-dotfiles/walls/2560x1600p/tokyo-text.png}"

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
    echo "Usage: $(basename "$0") </path/to/wallpaper.png | --theme <themename>>"
    echo "   or: echo /path/to/wallpaper.png | $(basename "$0")"
    exit 1
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
