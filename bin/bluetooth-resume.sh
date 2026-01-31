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

# Wait for Logitech mouse to reconnect (max 10 minutes)
timeout=600
elapsed=0
mouse_connected=0

while [[ $elapsed -lt $timeout ]]; do
  if grep -r "046D" /sys/class/input/mouse*/device/uevent 2>/dev/null >/dev/null; then
    mouse_connected=1
    break
  fi
  sleep 1
  ((elapsed++))
done

# Reload input-remapper if mouse is connected
if [[ $mouse_connected -eq 1 ]]; then
  echo "Mouse detected! Restarting input-remapper..."

  # Show warning notification
  notify-send -u normal "⌨️  Input Remapper" "Rechargement en cours...\n⚠️  Ne pas toucher la souris !" -t 5000 || true

  # Kill any existing input-remapper daemon processes
  echo "Killing existing input-remapper processes..."
  sudo pkill -9 input-remapper 2>/dev/null || true
  sleep 2

  # Restart the daemon
  echo "Starting input-remapper-service..."
  sudo input-remapper-service &
  sleep 2
  echo "Starting input-remapper-reader-service..."
  sudo input-remapper-reader-service &
  sleep 3

  # Wait for daemon to be ready
  echo "Waiting for daemon to be ready..."
  for i in {1..10}; do
    if input-remapper-control --command hello 2>/dev/null | grep -q "hello"; then
      echo "Daemon is ready after ${i} attempts"
      break
    fi
    sleep 1
  done

  # Now load the mappings (first attempt)
  echo "Loading mappings with autoload (attempt 1)..."
  input-remapper-control --command autoload 2>&1 || echo "Autoload failed!"
  sleep 3

  # Stop and reload again to ensure it's really active
  echo "Stopping all injections..."
  input-remapper-control --command stop-all 2>&1 || true
  sleep 2

  # Load again (second attempt)
  echo "Loading mappings with autoload (attempt 2)..."
  input-remapper-control --command autoload 2>&1 || echo "Autoload 2 failed!"
  sleep 3

  # Close previous notification and show completion
  swaync-client -C || true
  notify-send -u normal "⌨️  Input Remapper" "✓ Rechargement terminé" -t 2000 || true
  echo "Input-remapper reload complete"
else
  echo "Mouse not detected after ${timeout}s"
  notify-send -u normal "⌨️  Input Remapper" "⚠️  Souris non détectée après 10min, rechargement annulé" -t 3000 || true
fi
