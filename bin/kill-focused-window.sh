#!/usr/bin/env sh
PID=$(niri msg focused-window | grep PID | awk '{print $2}')
if [ -n "$PID" ]; then
    kill -9 "$PID"
fi
