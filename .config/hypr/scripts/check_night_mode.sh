#!/usr/bin/env bash
if pgrep -x "wlsunset" > /dev/null; then
    echo true
else
    echo false
fi
