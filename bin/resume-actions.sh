#!/usr/bin/env bash
# Actions to perform after system resume from sleep

# Log file
LOGFILE="$HOME/.local/share/resume-actions.log"
echo "$(date): Resume actions started" >> "$LOGFILE"

# Update theme based on time of day
~/nixos-config/bin/theme-auto-switch.sh &

# The monitor may have reset its brightness while asleep, and its DDC/CI
# channel is unreliable while it wakes up: forget the last applied value and
# re-apply shortly after wake-up, then once more in case the monitor reverted
# its brightness while finishing its power-up.
(
    for delay in 5 10; do
        sleep "$delay"
        rm -f /tmp/brightness-state
        ~/nixos-config/bin/theme-auto-switch.sh
    done
) &
disown

# Reconnect Bluetooth devices and reload input-remapper
# Note: NOT running in background because it needs to wait for mouse
echo "$(date): Starting bluetooth-resume.sh" >> "$LOGFILE"
~/nixos-config/bin/bluetooth-resume.sh >> "$LOGFILE" 2>&1

# Wait for all background jobs to complete
wait

echo "$(date): Resume actions completed" >> "$LOGFILE"
