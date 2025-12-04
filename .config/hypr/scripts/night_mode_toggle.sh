#!/usr/bin/env bash
UNIT="wlsunset-manual"

if systemctl --user is-active --quiet "$UNIT"; then
    systemctl --user stop "$UNIT"
else
    # Reset failed state if any
    systemctl --user reset-failed "$UNIT" 2>/dev/null
    # Start wlsunset as a transient user service
    systemd-run --user --unit="$UNIT" wlsunset -t 3500 -T 3501
fi