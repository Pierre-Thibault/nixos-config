#!/usr/bin/env bash
# OCR script using grim + slurp + tesseract

# Temporary file
TEMP_IMG="/tmp/ocr-screenshot-$$.png"

# Capture selected area
grim -g "$(slurp)" "$TEMP_IMG" || exit 1

# Perform OCR
TEXT=$(tesseract "$TEMP_IMG" - -l fra+eng+spa 2>/dev/null)

# Clean up
rm -f "$TEMP_IMG"

# Copy to clipboard if we got text
if [ -n "$TEXT" ]; then
    echo -n "$TEXT" | wl-copy
    notify-send "OCR" "Texte copié dans le presse-papiers"
else
    notify-send "OCR" "Aucun texte détecté" --urgency=critical
fi
