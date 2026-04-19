#!/usr/bin/env bash
# Auto-switch theme based on sunrise/sunset
# Coordinates: 45.9°N, 74.2°W (Montreal area)

THEME_TOGGLE_SCRIPT="/home/pierre/.config/waybar/theme-toggle.sh"
STATE_FILE="/home/pierre/.config/waybar/theme-state"
SUNTIMES_CACHE="/tmp/suntimes-cache"
SUNTIMES_LOCK="/tmp/suntimes-cache.lock"

# Check if we have cached sun times from today
if [ -f "$SUNTIMES_CACHE" ]; then
    CACHE_DATE=$(head -1 "$SUNTIMES_CACHE")
    TODAY=$(date +%Y-%m-%d)
    if [ "$CACHE_DATE" = "$TODAY" ]; then
        # Use cached values (format HH:MM)
        SUNRISE_TIME=$(sed -n '2p' "$SUNTIMES_CACHE")
        SUNSET_TIME=$(sed -n '3p' "$SUNTIMES_CACHE")
        SUNRISE_HOUR=${SUNRISE_TIME%:*}
        SUNRISE_MIN=${SUNRISE_TIME#*:}
        SUNSET_HOUR=${SUNSET_TIME%:*}
        SUNSET_MIN=${SUNSET_TIME#*:}
    else
        CACHE_DATE=""
    fi
fi

# Fetch new sun times if cache is invalid
if [ -z "$CACHE_DATE" ]; then
    (
        flock -n 9 || exit 0

        # Re-check cache inside the lock (another instance may have just written it)
        if [ -f "$SUNTIMES_CACHE" ]; then
            CACHE_DATE_INNER=$(head -1 "$SUNTIMES_CACHE")
            TODAY_INNER=$(date +%Y-%m-%d)
            if [ "$CACHE_DATE_INNER" = "$TODAY_INNER" ]; then
                exit 0
            fi
        fi

        # Wait for network connectivity (max 30s)
        nm-online -q -t 30 2>/dev/null || true

        # Fetch from sunrise-sunset.org API (Montreal coordinates)
        if RESPONSE=$(curl -s --connect-timeout 10 "https://api.sunrise-sunset.org/json?lat=45.9&lng=-74.2&formatted=0&tzid=America/Toronto"); then
            # Extract sunrise and sunset times (in ISO 8601 format)
            SUNRISE=$(echo "$RESPONSE" | grep -o '"sunrise":"[^"]*"' | cut -d'"' -f4)
            SUNSET=$(echo "$RESPONSE" | grep -o '"sunset":"[^"]*"' | cut -d'"' -f4)

            # Convert to hour and minutes (local time)
            SUNRISE_HOUR=$(date -d "$SUNRISE" +%H 2>/dev/null || echo 07)
            SUNRISE_MIN=$(date -d "$SUNRISE" +%M 2>/dev/null || echo 00)
            SUNSET_HOUR=$(date -d "$SUNSET" +%H 2>/dev/null || echo 19)
            SUNSET_MIN=$(date -d "$SUNSET" +%M 2>/dev/null || echo 00)

            # Write atomically to avoid partial reads
            TMPFILE=$(mktemp "${SUNTIMES_CACHE}.XXXXXX")
            printf '%s\n%s:%s\n%s:%s\n' \
                "$(date +%Y-%m-%d)" \
                "$SUNRISE_HOUR" "$SUNRISE_MIN" \
                "$SUNSET_HOUR" "$SUNSET_MIN" > "$TMPFILE"
            mv "$TMPFILE" "$SUNTIMES_CACHE"
        else
            # Fallback values if API fails
            SUNRISE_HOUR=7
            SUNRISE_MIN=00
            SUNSET_HOUR=17
            SUNSET_MIN=00
        fi
    ) 9>"$SUNTIMES_LOCK"

    # Re-read cache after lock block (may have been written by this or another instance)
    if [ -f "$SUNTIMES_CACHE" ]; then
        SUNRISE_TIME=$(sed -n '2p' "$SUNTIMES_CACHE")
        SUNSET_TIME=$(sed -n '3p' "$SUNTIMES_CACHE")
        SUNRISE_HOUR=${SUNRISE_TIME%:*}
        SUNRISE_MIN=${SUNRISE_TIME#*:}
        SUNSET_HOUR=${SUNSET_TIME%:*}
        SUNSET_MIN=${SUNSET_TIME#*:}
    fi
fi

CURRENT_TIME=$(date +%H:%M)
CURRENT_MINUTES=$((10#${CURRENT_TIME%:*} * 60 + 10#${CURRENT_TIME#*:}))
SUNRISE_MINUTES=$((10#$SUNRISE_HOUR * 60 + 10#$SUNRISE_MIN))
SUNSET_MINUTES=$((10#$SUNSET_HOUR * 60 + 10#$SUNSET_MIN - 15))  # 15 min avant le coucher

# Determine if it should be light or dark
if [ "$CURRENT_MINUTES" -ge "$SUNRISE_MINUTES" ] && [ "$CURRENT_MINUTES" -lt "$SUNSET_MINUTES" ]; then
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
