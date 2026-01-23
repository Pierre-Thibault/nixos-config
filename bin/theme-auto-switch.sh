#!/usr/bin/env bash
# Auto-switch theme based on sunrise/sunset
# Coordinates: 45.9°N, 74.2°W (Montreal area)

THEME_TOGGLE_SCRIPT="/home/pierre/.config/waybar/theme-toggle.sh"
STATE_FILE="/home/pierre/.config/waybar/theme-state"
SUNTIMES_CACHE="/tmp/suntimes-cache"

# Get current time in seconds since epoch
CURRENT_TIMESTAMP=$(date +%s)

# Check if we have cached sun times from today
if [ -f "$SUNTIMES_CACHE" ]; then
    CACHE_DATE=$(head -1 "$SUNTIMES_CACHE")
    TODAY=$(date +%Y-%m-%d)
    if [ "$CACHE_DATE" = "$TODAY" ]; then
        # Use cached values
        SUNRISE_HOUR=$(sed -n '2p' "$SUNTIMES_CACHE")
        SUNSET_HOUR=$(sed -n '3p' "$SUNTIMES_CACHE")
    else
        CACHE_DATE=""
    fi
fi

# Fetch new sun times if cache is invalid
if [ -z "$CACHE_DATE" ]; then
    # Fetch from sunrise-sunset.org API (Montreal coordinates)
    RESPONSE=$(curl -s "https://api.sunrise-sunset.org/json?lat=45.9&lng=-74.2&formatted=0&tzid=America/Toronto")

    if [ $? -eq 0 ]; then
        # Extract sunrise and sunset times (in ISO 8601 format)
        SUNRISE=$(echo "$RESPONSE" | grep -o '"sunrise":"[^"]*"' | cut -d'"' -f4)
        SUNSET=$(echo "$RESPONSE" | grep -o '"sunset":"[^"]*"' | cut -d'"' -f4)

        # Convert to hour (local time)
        SUNRISE_HOUR=$(date -d "$SUNRISE" +%H 2>/dev/null || echo 7)
        SUNSET_HOUR=$(date -d "$SUNSET" +%H 2>/dev/null || echo 17)

        # Cache the results
        echo "$(date +%Y-%m-%d)" > "$SUNTIMES_CACHE"
        echo "$SUNRISE_HOUR" >> "$SUNTIMES_CACHE"
        echo "$SUNSET_HOUR" >> "$SUNTIMES_CACHE"
    else
        # Fallback values if API fails
        SUNRISE_HOUR=7
        SUNSET_HOUR=17
    fi
fi

HOUR=$(date +%H)

# Determine if it should be light or dark
if [ "$HOUR" -ge "$SUNRISE_HOUR" ] && [ "$HOUR" -lt "$SUNSET_HOUR" ]; then
    DESIRED_THEME="light"
else
    DESIRED_THEME="dark"
fi

# Read current state
CURRENT_THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "unknown")

# Only change if different
if [ "$DESIRED_THEME" != "$CURRENT_THEME" ]; then
    "$THEME_TOGGLE_SCRIPT" "$DESIRED_THEME"
fi
