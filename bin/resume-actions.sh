#!/usr/bin/env bash
# Actions to perform after system resume from sleep

# Update theme based on time of day
~/nixos-config/bin/theme-auto-switch.sh &

# Reconnect Bluetooth devices
~/nixos-config/bin/bluetooth-resume.sh &

# Wait for all background jobs to complete
wait
