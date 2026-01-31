#!/usr/bin/env bash
# Actions to perform after system resume from sleep

# Log file
LOGFILE="$HOME/.local/share/resume-actions.log"
echo "$(date): Resume actions started" >> "$LOGFILE"

# Update theme based on time of day
~/nixos-config/bin/theme-auto-switch.sh &

# Reconnect Bluetooth devices and reload input-remapper
# Note: NOT running in background because it needs to wait for mouse
echo "$(date): Starting bluetooth-resume.sh" >> "$LOGFILE"
~/nixos-config/bin/bluetooth-resume.sh >> "$LOGFILE" 2>&1

# Wait for all background jobs to complete
wait
echo "$(date): Resume actions completed" >> "$LOGFILE"
