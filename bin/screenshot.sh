#!/usr/bin/env bash
# Screenshot script with sound feedback
# Usage: screenshot.sh [--region|--full] [--edit]

SOUND="$(dirname "$(readlink -f "$0")")/camera-shutter.oga"
SCREENSHOT_DIR="$HOME/Images/Captures d'écran"
FILENAME="Capture d'écran du $(date '+%Y-%m-%d %H-%M-%S').png"

MODE="region"
EDIT=false

for arg in "$@"; do
    case "$arg" in
        --full) MODE="full" ;;
        --edit) EDIT=true ;;
    esac
done

# Capture
if [ "$MODE" = "region" ]; then
    SELECTION=$(slurp) || exit 1
    GRIM_ARGS=(-g "$SELECTION")
else
    GRIM_ARGS=()
fi

TMPFILE=$(mktemp /tmp/screenshot-XXXXXX.png)

grim "${GRIM_ARGS[@]}" "$TMPFILE" || { rm -f "$TMPFILE"; exit 1; }

if [ "$EDIT" = true ]; then
    swappy -f "$TMPFILE"
else
    cp "$TMPFILE" "$SCREENSHOT_DIR/$FILENAME"
    wl-copy < "$TMPFILE"
fi

rm -f "$TMPFILE"

pw-play "$SOUND" &
