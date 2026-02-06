#!/usr/bin/env bash
# Force Bluetooth reconnection after system resume

# Wait a moment for the system to stabilize
sleep 2

# Power on Bluetooth radio
bluetoothctl power on 2>/dev/null || true

# Wait a bit for Bluetooth to initialize
sleep 1

# Try to reconnect to previously connected devices
# Get list of paired devices and try to connect
bluetoothctl devices Paired | cut -d' ' -f2 | while read -r device; do
    bluetoothctl connect "$device" 2>/dev/null &
done

# Clean up background jobs after 5 seconds
(sleep 5; jobs -p | xargs -r kill 2>/dev/null) &

echo "Bluetooth reconnection initiated"
# Note: Input-remapper is now managed by systemd timer (input-remapper-watchdog.timer)
