#!/bin/bash
# qs_control.sh - Control script for quickshell widgets + OSD actions
# Usage: qs_control.sh <command> [args]
# Commands:
#   launcher, wallpaper, power, notifications, volume, network, bluetooth, calendar, close, toggle, status
#   volume-up, volume-down, volume-mute, mic-mute, brightness-up, brightness-down, sync-mic-led

CMD="${1:-toggle}"
ARG="${2:-}"
LAST_BRIGHTNESS_TS_FILE="/tmp/qs_last_brightness_key_ts"

# Get active monitor info from hyprctl
get_monitor_info() {
    local mon_info
    mon_info=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.x):\(.y):\(.width):\(.height)"')
    echo "$mon_info"
}

# Write command to IPC file
write_command() {
    local widget="$1"
    local arg="$2"
    local mon_info
    mon_info=$(get_monitor_info)
    
    if [ -n "$mon_info" ]; then
        echo "${widget}:${arg}:${mon_info}" > /tmp/qs_widget_state
    else
        echo "${widget}:${arg}:0:0:1920:1080" > /tmp/qs_widget_state
    fi
}

show_osd() {
    local kind="$1"
    local value="$2"
    echo "${kind}:${value}" > /tmp/qs_osd_state
}

get_mic_muted_state() {
    local mic_muted
    mic_muted=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | awk '{print tolower($2)}')
    if [ -z "$mic_muted" ] && command -v pamixer >/dev/null 2>&1; then
        mic_muted=$(pamixer --default-source --get-mute 2>/dev/null | tr '[:upper:]' '[:lower:]')
    fi
    case "$mic_muted" in
        yes|true|1)
            echo "yes"
            ;;
        *)
            echo "no"
            ;;
    esac
}

sync_mic_led() {
    if ! command -v hda-verb >/dev/null 2>&1; then
        return
    fi
    if [ ! -e /dev/snd/hwC0D0 ]; then
        return
    fi

    local mic_muted
    mic_muted=$(get_mic_muted_state)

    # HP EliteBook 840 G6 mic LED control via GPIO.
    if [ "$mic_muted" = "yes" ]; then
        sudo -n hda-verb /dev/snd/hwC0D0 0x1 SET_GPIO_DATA 0x1 >/dev/null 2>&1 || true
    else
        sudo -n hda-verb /dev/snd/hwC0D0 0x1 SET_GPIO_DATA 0x0 >/dev/null 2>&1 || true
    fi
}

now_ms() {
    date +%s%3N 2>/dev/null || echo 0
}

mark_brightness_key_event() {
    now_ms > "$LAST_BRIGHTNESS_TS_FILE" 2>/dev/null || true
}

mic_toggle_likely_from_brightness_key() {
    [ -f "$LAST_BRIGHTNESS_TS_FILE" ] || return 1

    local now
    local last
    now=$(now_ms)
    last=$(cat "$LAST_BRIGHTNESS_TS_FILE" 2>/dev/null)

    case "$now:$last" in
        *[!0-9:]*|:|0:*|*:)
            return 1
            ;;
    esac

    # Some laptop firmwares emit a stray mic-mute event with brightness keys.
    # Ignore mic toggles that arrive within a short window after brightness keys.
    if [ $(( now - last )) -lt 280 ]; then
        return 0
    fi

    return 1
}

case "$CMD" in
    launcher|wallpaper|power|notifications|volume|network|bluetooth|calendar)
        write_command "$CMD" "$ARG"
        ;;
    volume-up)
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%')
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
        if [ "$muted" = "yes" ]; then
            show_osd "volume-muted" "${vol:-0}"
        else
            show_osd "volume" "${vol:-0}"
        fi
        ;;
    volume-down)
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%')
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
        if [ "$muted" = "yes" ]; then
            show_osd "volume-muted" "${vol:-0}"
        else
            show_osd "volume" "${vol:-0}"
        fi
        ;;
    volume-mute)
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')
        vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -oE '[0-9]+%' | head -1 | tr -d '%')
        if [ "$muted" = "yes" ]; then
            show_osd "volume-muted" "${vol:-0}"
        else
            show_osd "volume" "${vol:-0}"
        fi
        ;;
    mic-mute)
        if mic_toggle_likely_from_brightness_key; then
            exit 0
        fi

        pactl set-source-mute @DEFAULT_SOURCE@ toggle >/dev/null 2>&1
        sync_mic_led

        mic_muted=$(get_mic_muted_state)
        if [ "$mic_muted" = "yes" ]; then
            show_osd "mic" "1"
        else
            show_osd "mic" "0"
        fi
        ;;
    brightness-up)
        mark_brightness_key_event
        brightnessctl set +5% >/dev/null 2>&1
        br=$(brightnessctl g 2>/dev/null)
        max=$(brightnessctl m 2>/dev/null)
        if [ -z "$br" ] || [ -z "$max" ] || [ "$max" -eq 0 ]; then
            pct=0
        else
            pct=$(( br * 100 / max ))
        fi
        show_osd "brightness" "${pct:-0}"
        ;;
    brightness-down)
        mark_brightness_key_event
        brightnessctl set 5%- >/dev/null 2>&1
        br=$(brightnessctl g 2>/dev/null)
        max=$(brightnessctl m 2>/dev/null)
        if [ -z "$br" ] || [ -z "$max" ] || [ "$max" -eq 0 ]; then
            pct=0
        else
            pct=$(( br * 100 / max ))
        fi
        if [ "${pct:-0}" -lt 5 ]; then
            brightnessctl set 5% >/dev/null 2>&1
            br=$(brightnessctl g 2>/dev/null)
            max=$(brightnessctl m 2>/dev/null)
            if [ -z "$br" ] || [ -z "$max" ] || [ "$max" -eq 0 ]; then
                pct=0
            else
                pct=$(( br * 100 / max ))
            fi
        fi
        show_osd "brightness" "${pct:-0}"
        ;;
    sync-mic-led)
        sync_mic_led
        ;;
    close)
        echo "close" > /tmp/qs_widget_state
        ;;
    toggle)
        # Toggle the launcher by default
        write_command "launcher" ""
        ;;
    status)
        cat /tmp/qs_active_widget 2>/dev/null || echo "hidden"
        ;;
    *)
        echo "Unknown command: $CMD"
        echo "Usage: $0 {launcher|wallpaper|power|notifications|volume|network|bluetooth|calendar|close|toggle|status|volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down|sync-mic-led}"
        exit 1
        ;;
esac
