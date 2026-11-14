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

# ==============================================================================
# FROSTED LOCKSCREEN SETTINGS (dual_kawase + frosted glass effect)
# Modify any of these values to tune how frosted your lockscreen looks!
# Changes take effect automatically the next time you press Super+Shift+L
# (or run `themeswitch` / `themeswitch --frost-only`).
# ==============================================================================
FROST_BLUR_STRENGTH="2.5"  # Blur sigma per Kawase pass (0.5 = crisp, 2.5 = medium frost, 6.0 = heavy blur)
FROST_DOWNSAMPLE="60"      # Kawase downsample % (10 = ultra-wide dreamy blur, 25 = balanced, 60 = very light)
FROST_WHITE_GLAZE="12"     # Milky white frosted glass sheen % (0 = none, 12 = frosted glass, 25 = icy white)
FROST_THEME_TINT="0"       # Theme background tint % (0 = original colors, 6 = subtle tint; >15 will darken the image)
FROST_GRAIN="0.11"         # Etched glass micro-grain (0 = smooth blur, 0.22 = frosted texture, 0.50 = sandblasted)

CACHE_DIR="$HOME/.cache/matugen"
DEFAULT_WALLPAPER="$HOME/nixos-dotfiles/walls/2560x1600p/tokyo-text.png"
MATUGEN_CONFIG="$HOME/.config/matugen/config.toml"
[ -f "$MATUGEN_CONFIG" ] || MATUGEN_CONFIG="$HOME/nixos-dotfiles/config/matugen/config.toml"

generate_frosted_lock_wallpaper() {
    local src_wall="$1"
    if [ ! -f "$src_wall" ] && [ -f "$CACHE_DIR/wallpaper" ]; then
        src_wall="$(cat "$CACHE_DIR/wallpaper")"
    fi
    if [ ! -f "$src_wall" ]; then
        src_wall="$DEFAULT_WALLPAPER"
    fi
    [ -f "$src_wall" ] || return 0
    command -v magick >/dev/null 2>&1 || return 0

    mkdir -p "$CACHE_DIR"
    local bg_hex="#1a1b26"
    if [ -f "$CACHE_DIR/colors-lock.sh" ]; then
        bg_hex="$(grep -E "^background=" "$CACHE_DIR/colors-lock.sh" | cut -d"'" -f2)"
    fi

    local sig="v2|${src_wall}|${FROST_BLUR_STRENGTH}|${FROST_DOWNSAMPLE}|${FROST_WHITE_GLAZE}|${FROST_THEME_TINT}|${FROST_GRAIN}|${bg_hex}"
    if [ -f "$CACHE_DIR/lock-wallpaper.png" ] && [ -f "$CACHE_DIR/lock-wallpaper.sig" ]; then
        if [ "$(cat "$CACHE_DIR/lock-wallpaper.sig" 2>/dev/null)" = "$sig" ]; then
            return 0
        fi
    fi

    # Dual-Kawase downsample -> etched grain -> upsample -> theme tint -> milky frost glaze
    magick "$src_wall" \
        -resize 2560x1600^ -gravity center -extent 2560x1600 \
        -filter Triangle \
        -resize "${FROST_DOWNSAMPLE}%" -blur "0x${FROST_BLUR_STRENGTH}" \
        -resize 60% -blur "0x${FROST_BLUR_STRENGTH}" \
        -attenuate "$FROST_GRAIN" +noise Gaussian \
        -resize 166% -blur "0x1.2" \
        -resize 2560x1600! \
        -fill "${bg_hex:-#1a1b26}" -colorize "${FROST_THEME_TINT}%" \
        -fill "#ffffff" -colorize "${FROST_WHITE_GLAZE}%" \
        -define png:compression-level=1 \
        "$CACHE_DIR/lock-wallpaper.tmp.png" 2>/dev/null && \
    mv -f "$CACHE_DIR/lock-wallpaper.tmp.png" "$CACHE_DIR/lock-wallpaper.png" && \
    printf '%s' "$sig" > "$CACHE_DIR/lock-wallpaper.sig"
}

if [ "$1" = "--frost-only" ]; then
    generate_frosted_lock_wallpaper "$2"
    exit 0
fi

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
            echo "Usage: $(basename "$0") [/path/to/wallpaper.png] [-t|--type <scheme>] [--color \"#RRGGBB\"] [--restore] [--frost-only [wallpaper]]"
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
    echo "Usage: $(basename "$0") [/path/to/wallpaper.png] [-t|--type <scheme>] [--color \"#RRGGBB\"] [--restore] [--frost-only [wallpaper]]" >&2
    echo "   or: echo /path/to/wallpaper.png | $(basename "$0")" >&2
    exit 1
fi

printf '%s' "$SCHEME" > "$CACHE_DIR/scheme"

echo "==> Generating dual_kawase frosted lockscreen wallpaper..."
generate_frosted_lock_wallpaper "$WALLPAPER" &
FROST_PID=$!

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
for sock in $(find "${XDG_RUNTIME_DIR:-/tmp}" -maxdepth 2 \( -name "nvim*.0" -o -name "nvim*" \) 2>/dev/null); do
    if [ -S "$sock" ]; then
        nvim --server "$sock" --remote-send "<Esc>:colorscheme matugen<CR>" 2>/dev/null || true
    fi
done

echo "==> Updating Firefox..."
# MatugenFox's native host (matugenfox_host.py) polls firefox_websites.css mtime every 2s
[ -f "$HOME/.config/matugen/generated/firefox_websites.css" ] || true

echo "==> Updating Obsidian..."
# Snippet output is written directly by matugen into the active vault's snippets/ folder
true

echo "==> Updating Anki..."
touch "$CACHE_DIR/anki-reload" 2>/dev/null || true

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

wait "$FROST_PID" 2>/dev/null || true

echo "==> Theme switch complete!"
