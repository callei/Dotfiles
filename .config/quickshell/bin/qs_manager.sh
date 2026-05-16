#!/usr/bin/env bash
# qs_manager.sh - Small IPC manager for quickshell widget toggles/state
set -euo pipefail

IPC_FILE="/tmp/qs_widget_state"
ACTIVE_FILE="/tmp/qs_active_widget"

current_widget() {
    if [ -f "$ACTIVE_FILE" ]; then
        cat "$ACTIVE_FILE"
    else
        echo "hidden"
    fi
}

write_ipc() {
    printf '%s\n' "$1" > "$IPC_FILE"
}

toggle_widget() {
    local target="$1"
    local current
    current="$(current_widget)"

    if [ "$current" = "$target" ]; then
        write_ipc "close"
    else
        write_ipc "$target"
    fi
}

usage() {
    echo "Usage: $0 {launcher|wallpaper|network|bluetooth|notifications|power|close|toggle [widget]|status}" >&2
    exit 1
}

cmd="${1:-toggle}"
arg="${2:-launcher}"

case "$cmd" in
    launcher|wallpaper|network|bluetooth|notifications|power)
        write_ipc "$cmd"
        ;;
    close)
        write_ipc "close"
        ;;
    toggle)
        case "$arg" in
            launcher|wallpaper|network|bluetooth|notifications|power)
                toggle_widget "$arg"
                ;;
            *)
                usage
                ;;
        esac
        ;;
    status)
        current_widget
        ;;
    *)
        usage
        ;;
esac
