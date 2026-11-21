#!/usr/bin/env bash
set -euo pipefail

ICON_UNMUTED=""
ICON_MUTED=""

out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
if [ -z "$out" ]; then
    printf '%s --\n' "$ICON_MUTED"
    exit 0
fi

awk -v unmuted="$ICON_UNMUTED" -v muted="$ICON_MUTED" '
{
    vol = int($2 * 100 + 0.5)
    if ($0 ~ /\[MUTED\]/) {
        printf "%s %d\n", muted, vol
    } else {
        printf "%s %d\n", unmuted, vol
    }
}' <<< "$out"
