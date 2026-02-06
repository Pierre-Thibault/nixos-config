#!/usr/bin/env bash
# Check and reload input-remapper mappings if needed

# Check if daemon responds
HELLO_OUTPUT=$(input-remapper-control --command hello 2>&1)
echo "Hello command output: $HELLO_OUTPUT"
if ! echo "$HELLO_OUTPUT" | grep -q "hello"; then
    echo "ERROR: Daemon not responding"
    exit 1
fi

# Always autoload mappings (autoload is idempotent - won't reload if already loaded)
echo "Loading mappings..."
input-remapper-control --command autoload 2>&1 | grep -v "UserWarning"

# Verify there are injector processes running (more than 2 base processes)
PROCESS_COUNT=$(pgrep -c input-remapper 2>/dev/null || echo 0)
if [ "$PROCESS_COUNT" -gt 2 ]; then
    echo "Input-remapper OK ($PROCESS_COUNT processes)"
    exit 0
else
    echo "WARNING: Only $PROCESS_COUNT input-remapper processes (mappings may not be loaded)"
    exit 0  # Don't fail, just warn
fi
