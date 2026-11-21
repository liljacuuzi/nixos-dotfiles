#!/usr/bin/env bash
# Launches yazi with live Matugen theme reload support on SIGUSR1.
set -u

# Pass through directly if non-interactive or caller manages cwd/client-id/chooser flags
for arg in "$@"; do
    case "$arg" in
        -V|--version|-h|--help|--chooser-file*|--cwd-file*|--client-id*|--local-events*|--remote-events*)
            exec yazi "$@"
            ;;
    esac
done

CLIENT_ID="$$"
PID_DIR="${XDG_RUNTIME_DIR:-/tmp}/yazi-matugen"
mkdir -p "$PID_DIR"
PID_FILE="$PID_DIR/$CLIENT_ID"
touch "$PID_FILE"

CWD_FILE="$(mktemp -t yazi-cwd.XXXXXX)"
RELOAD=0

cleanup() {
    rm -f "$CWD_FILE" "$PID_FILE"
}
trap cleanup EXIT

on_reload() {
    RELOAD=1
    ya emit-to "$CLIENT_ID" quit >/dev/null 2>&1 || true
}
trap on_reload USR1

args=("$@")
while true; do
    RELOAD=0
    yazi --client-id "$CLIENT_ID" --cwd-file "$CWD_FILE" "${args[@]}" <&0 &
    YAZI_PID=$!

    wait "$YAZI_PID" 2>/dev/null || true
    # If wait was interrupted by SIGUSR1, wait for yazi to finish exiting
    wait "$YAZI_PID" 2>/dev/null || true

    if [ "$RELOAD" -eq 1 ]; then
        if [ -s "$CWD_FILE" ]; then
            new_cwd="$(cat "$CWD_FILE")"
            if [ -n "$new_cwd" ] && [ -d "$new_cwd" ]; then
                args=("$new_cwd")
            fi
        fi
        continue
    fi
    break
done
