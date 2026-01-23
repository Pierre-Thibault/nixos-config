#!/usr/bin/env bash
# Daemon to check and switch theme every 5 minutes

while true; do
    /home/pierre/nixos-config/bin/theme-auto-switch.sh
    sleep 300  # Check every 5 minutes
done
