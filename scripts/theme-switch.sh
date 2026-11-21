#!/usr/bin/env bash
set -e

# ==============================================================================
# MATUGEN SCHEME TYPE
# Change this single variable if you want to switch Material You scheme styles
# later. Valid options in matugen 4.2.0:
#   scheme-fidelity, scheme-tonal-spot, scheme-content, scheme-expressive,
#   scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow,
#   scheme-vibrant, scheme-smart
# ==============================================================================
MATUGEN_SCHEME="scheme-fidelity"

CACHE_DIR="$HOME/.cache/matugen"
DEFAULT_WALLPAPER="$HOME/nixos-dotfiles/walls/2560x1600p/tokyo-text.png"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
[ -f "$MATUGEN_CONFIG" ] || MATUGEN_CONFIG="$HOME/nixos-dotfiles/config/matugen/config.toml"

SCHEME="$MATUGEN_SCHEME"
HEX_COLOR=""
RESTORE=0
INPUT=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        -t|--type)
            if [ -z "${2:-}" ]; then
                echo "Error: $1 requires a matugen scheme type argument." >&2
                exit 1
            fi
            SCHEME="$2"
            shift 2
            ;;
        --color)
            if [ -z "${2:-}" ]; then
                echo "Error: --color requires a hex color (e.g. \"#7aa2f7\")." >&2
                exit 1
            fi
            HEX_COLOR="$2"
            shift 2
            ;;
        --restore)
            RESTORE=1
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [/path/to/wallpaper.png] [-t|--type <scheme>] [--color \"#RRGGBB\"] [--restore]"
            echo "   or: echo /path/to/wallpaper.png | $(basename "$0")"
            exit 0
            ;;
        *)
            INPUT="$1"
            shift
            ;;
    esac
done

if [ -z "$INPUT" ] && [ -z "$HEX_COLOR" ] && [ "$RESTORE" -eq 0 ] && [ ! -t 0 ]; then
    read -r INPUT
fi

# Expand tilde ~ and trim whitespace without touching valid paths unnecessarily
INPUT="${INPUT/#\~/$HOME}"
INPUT="$(printf '%s' "$INPUT" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

ACTIVE_WALL=""
if [ -f "$CACHE_DIR/wallpaper" ]; then
    ACTIVE_WALL="$(cat "$CACHE_DIR/wallpaper")"
fi
WALLPAPER="${INPUT:-${ACTIVE_WALL:-$DEFAULT_WALLPAPER}}"

mkdir -p "$CACHE_DIR"

# 1. Generate palette using matugen
if [ -n "$HEX_COLOR" ]; then
    echo "==> Generating palette ($SCHEME) from color: $HEX_COLOR"
    matugen color hex "$HEX_COLOR" -c "$MATUGEN_CONFIG" -t "$SCHEME" --mode dark --source-color-index 0 -q
elif [ -f "$WALLPAPER" ]; then
    echo "==> Generating palette from wallpaper: $WALLPAPER"
    matugen image "$WALLPAPER" -c "$MATUGEN_CONFIG" -t "$SCHEME" --mode dark --source-color-index 0 -q
    printf '%s' "$WALLPAPER" > "$CACHE_DIR/wallpaper"
    if [ -n "${DISPLAY:-}" ] && command -v feh >/dev/null 2>&1; then
        feh --bg-scale "$WALLPAPER"
    fi
else
    echo "Error: File '$WALLPAPER' not found." >&2
    echo "Usage: $(basename "$0") [/path/to/wallpaper.png] [-t|--type <scheme>] [--color \"#RRGGBB\"] [--restore]" >&2
    echo "   or: echo /path/to/wallpaper.png | $(basename "$0")" >&2
    exit 1
fi

printf '%s' "$SCHEME" > "$CACHE_DIR/scheme"

echo "==> Updating SilentSDDM theme..."
SDDM_MATUGEN_DIR="/var/cache/matugen-sddm"
if [ -d "$SDDM_MATUGEN_DIR" ]; then
    if [ -f "$CACHE_DIR/silent.conf" ]; then
        cp -f "$CACHE_DIR/silent.conf" "$SDDM_MATUGEN_DIR/silent.conf" 2>/dev/null || true
    fi
    if [ -f "$WALLPAPER" ]; then
        cp -f "$WALLPAPER" "$SDDM_MATUGEN_DIR/wallpaper.png" 2>/dev/null || true
    fi
    chmod 644 "$SDDM_MATUGEN_DIR"/* 2>/dev/null || true
fi

echo "==> Updating Xresources database..."
if [ -n "${DISPLAY:-}" ] && [ -f "$CACHE_DIR/colors.Xresources" ] && command -v xrdb >/dev/null 2>&1; then
    xrdb -merge "$CACHE_DIR/colors.Xresources"
fi

echo "==> Updating st terminals..."
if [ -f "$CACHE_DIR/sequences" ]; then
    for tty in /dev/pts/[0-9]*; do
        if [ -w "$tty" ]; then
            cat "$CACHE_DIR/sequences" > "$tty" 2>/dev/null || true
        fi
    done
fi
pkill -USR1 -x st 2>/dev/null || true

echo "==> Updating btop..."
pkill -USR2 -x btop 2>/dev/null || pkill -USR2 -x ".btop-wrapped" 2>/dev/null || true

echo "==> Updating bat..."
if command -v bat >/dev/null 2>&1 && [ -f "$HOME/.config/bat/themes/Matugen.tmTheme" ]; then
    bat cache --build >/dev/null 2>&1 || true
fi

echo "==> Updating dunst..."
if [ -n "${DISPLAY:-}" ]; then
    if pgrep -x dunst >/dev/null 2>&1 || pgrep -x .dunst-wrapped >/dev/null 2>&1; then
        if command -v dunstctl >/dev/null 2>&1; then
            if [ -f "$CACHE_DIR/dunstrc" ]; then
                dunstctl reload "$CACHE_DIR/dunstrc" 2>/dev/null || true
            else
                dunstctl reload 2>/dev/null || true
            fi
        fi
    elif command -v dunst >/dev/null 2>&1; then
        if [ -f "$CACHE_DIR/dunstrc" ]; then
            dunst -config "$CACHE_DIR/dunstrc" >/dev/null 2>&1 &
        else
            dunst >/dev/null 2>&1 &
        fi
    fi
fi

echo "==> Hot-reloading oxwm..."
if [ -n "${DISPLAY:-}" ] && command -v xdotool >/dev/null 2>&1; then
    xdotool key super+shift+r 2>/dev/null || true
fi

echo "==> Updating running Neovim instances..."
pkill -USR1 -x nvim 2>/dev/null || pkill -USR1 -x ".nvim-wrapped" 2>/dev/null || true

echo "==> Updating running Yazi instances..."
YAZI_PID_DIR="${XDG_RUNTIME_DIR:-/tmp}/yazi-matugen"
if [ -d "$YAZI_PID_DIR" ]; then
    for pidfile in "$YAZI_PID_DIR"/*; do
        [ -e "$pidfile" ] || continue
        ypid="$(basename "$pidfile")"
        if kill -0 "$ypid" 2>/dev/null; then
            kill -USR1 "$ypid" 2>/dev/null || true
        else
            rm -f "$pidfile"
        fi
    done
fi

echo "==> Updating Firefox..."
# MatugenFox's native host (matugenfox_host.py) polls firefox_websites.css mtime every 2s
[ -f "$HOME/.config/matugen/generated/firefox_websites.css" ] || true

echo "==> Updating Obsidian..."
# Snippet output is written directly by matugen into the active vault's snippets/ folder
true

echo "==> Updating Anki..."
touch "$CACHE_DIR/anki-reload" 2>/dev/null || true

echo "==> Updating keyboard RGB..."
if command -v oxwm-rgb-sync >/dev/null 2>&1; then
    oxwm-rgb-sync sync >/dev/null 2>&1 || true
fi

echo "==> Updating PCManFM-Qt..."
pcmanfm_running() {
    pgrep -x "pcmanfm-qt" >/dev/null 2>&1 || pgrep -x ".pcmanfm-qt-wra" >/dev/null 2>&1
}
PCMANFM_BIN="/etc/profiles/per-user/${USER:-$(id -un)}/bin/pcmanfm-qt"
[ -x "$PCMANFM_BIN" ] || PCMANFM_BIN="$(command -v pcmanfm-qt 2>/dev/null || true)"

if [ -n "${DISPLAY:-}" ] && [ -x "$PCMANFM_BIN" ] && pcmanfm_running; then
    PCMANFM_MODE=""
    PCMANFM_ARGS="$(ps -eo comm=,args= 2>/dev/null | awk '$1 == "pcmanfm-qt" || $1 == ".pcmanfm-qt-wra" { $1=""; print }')"
    case "$PCMANFM_ARGS" in
        *--desktop*) PCMANFM_MODE="--desktop" ;;
        *--daemon-mode*|*" -d"*) PCMANFM_MODE="-d" ;;
    esac

    "$PCMANFM_BIN" -q 2>/dev/null || true
    for _ in $(seq 1 20); do
        if ! pcmanfm_running; then
            break
        fi
        sleep 0.05
    done
    if pcmanfm_running; then
        pkill -TERM -x "pcmanfm-qt" 2>/dev/null || true
        pkill -TERM -x ".pcmanfm-qt-wra" 2>/dev/null || true
        sleep 0.1
    fi

    if [ -n "$PCMANFM_MODE" ]; then
        setsid "$PCMANFM_BIN" "$PCMANFM_MODE" >/dev/null 2>&1 &
    else
        setsid "$PCMANFM_BIN" >/dev/null 2>&1 &
    fi
fi

echo "==> Updating GTK apps..."
XSETTINGS_CONF="$HOME/.config/xsettingsd/xsettingsd.conf"
# Toggle between matugen-a and matugen-b so GTK detects a theme change and reloads CSS live
if [ -f "$XSETTINGS_CONF" ] && grep -q 'Net/ThemeName "matugen-a"' "$XSETTINGS_CONF"; then
    NEXT_THEME="matugen-b"
else
    NEXT_THEME="matugen-a"
fi

mkdir -p "$HOME/.config/xsettingsd"
cat << EOF > "$XSETTINGS_CONF"
Net/ThemeName "$NEXT_THEME"
Net/IconThemeName "Papirus-Dark"
Gtk/CursorThemeName "Adwaita"
EOF

pkill -HUP -x xsettingsd 2>/dev/null || true

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$NEXT_THEME" 2>/dev/null || true
fi

for ver in gtk-3.0 gtk-4.0; do
    if [ -f "$HOME/.config/$ver/settings.ini" ]; then
        sed -i "s/gtk-theme-name = .*/gtk-theme-name = $NEXT_THEME/" "$HOME/.config/$ver/settings.ini" 2>/dev/null || true
    fi
done

echo "==> Theme switch complete!"
