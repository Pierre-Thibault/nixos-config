#!/usr/bin/env bash
# Auto-switch theme based on sunrise/sunset, and ramp monitor brightness
# gradually between civil twilight and sunrise/sunset (100 during the day,
# 70 at night, smooth transition across each twilight window).

THEME_TOGGLE_SCRIPT="/home/pierre/.config/waybar/theme-toggle.sh"
STATE_FILE="/home/pierre/.config/waybar/theme-state"
SET_BRIGHTNESS="/home/pierre/nixos-config/bin/set-brightness"
BRIGHTNESS_STATE_FILE="/tmp/brightness-state"
SUNTIMES_CACHE="/tmp/suntimes-cache"
SUNTIMES_LOCK="/tmp/suntimes-cache.lock"
DAY_BRIGHTNESS=100
NIGHT_BRIGHTNESS=70

# Check if we have cached sun times from today
if [ -f "$SUNTIMES_CACHE" ]; then
    CACHE_DATE=$(head -1 "$SUNTIMES_CACHE")
    TODAY=$(date +%Y-%m-%d)
    if [ "$CACHE_DATE" = "$TODAY" ]; then
        # Use cached values (format HH:MM)
        SUNRISE_TIME=$(sed -n '2p' "$SUNTIMES_CACHE")
        SUNSET_TIME=$(sed -n '3p' "$SUNTIMES_CACHE")
        DAWN_TIME=$(sed -n '4p' "$SUNTIMES_CACHE")
        DUSK_TIME=$(sed -n '5p' "$SUNTIMES_CACHE")
        SUNRISE_HOUR=${SUNRISE_TIME%:*}
        SUNRISE_MIN=${SUNRISE_TIME#*:}
        SUNSET_HOUR=${SUNSET_TIME%:*}
        SUNSET_MIN=${SUNSET_TIME#*:}
        DAWN_HOUR=${DAWN_TIME%:*}
        DAWN_MIN=${DAWN_TIME#*:}
        DUSK_HOUR=${DUSK_TIME%:*}
        DUSK_MIN=${DUSK_TIME#*:}
        # Cache predates civil twilight fields: treat as stale
        if [ -z "$DAWN_TIME" ] || [ -z "$DUSK_TIME" ]; then
            CACHE_DATE=""
        fi
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

        # Fetch from sunrise-sunset.org API
        COORDS=$("$HOME/nixos-config/bin/get-location")
        LAT=$(echo "$COORDS" | cut -d' ' -f1)
        LON=$(echo "$COORDS" | cut -d' ' -f2)
        # Fallback if coordinates are empty (e.g. get-location not in PATH)
        if [ -z "$LAT" ] || [ -z "$LON" ]; then
            LAT="45.9"
            LON="-74.2"
        fi
        if RESPONSE=$(curl -s --connect-timeout 10 "https://api.sunrise-sunset.org/json?lat=${LAT}&lng=${LON}&formatted=0&tzid=America/Toronto"); then
            # Extract sunrise, sunset and civil twilight times (in ISO 8601 format)
            SUNRISE=$(echo "$RESPONSE" | grep -o '"sunrise":"[^"]*"' | cut -d'"' -f4)
            SUNSET=$(echo "$RESPONSE" | grep -o '"sunset":"[^"]*"' | cut -d'"' -f4)
            DAWN=$(echo "$RESPONSE" | grep -o '"civil_twilight_begin":"[^"]*"' | cut -d'"' -f4)
            DUSK=$(echo "$RESPONSE" | grep -o '"civil_twilight_end":"[^"]*"' | cut -d'"' -f4)

            # Convert to hour and minutes (local time)
            SUNRISE_HOUR=$(date -d "$SUNRISE" +%H 2>/dev/null || echo 07)
            SUNRISE_MIN=$(date -d "$SUNRISE" +%M 2>/dev/null || echo 00)
            SUNSET_HOUR=$(date -d "$SUNSET" +%H 2>/dev/null || echo 19)
            SUNSET_MIN=$(date -d "$SUNSET" +%M 2>/dev/null || echo 00)
            DAWN_HOUR=$(date -d "$DAWN" +%H 2>/dev/null || echo "$SUNRISE_HOUR")
            DAWN_MIN=$(date -d "$DAWN" +%M 2>/dev/null || echo "$SUNRISE_MIN")
            DUSK_HOUR=$(date -d "$DUSK" +%H 2>/dev/null || echo "$SUNSET_HOUR")
            DUSK_MIN=$(date -d "$DUSK" +%M 2>/dev/null || echo "$SUNSET_MIN")

            # Write atomically to avoid partial reads
            TMPFILE=$(mktemp "${SUNTIMES_CACHE}.XXXXXX")
            printf '%s\n%s:%s\n%s:%s\n%s:%s\n%s:%s\n' \
                "$(date +%Y-%m-%d)" \
                "$SUNRISE_HOUR" "$SUNRISE_MIN" \
                "$SUNSET_HOUR" "$SUNSET_MIN" \
                "$DAWN_HOUR" "$DAWN_MIN" \
                "$DUSK_HOUR" "$DUSK_MIN" > "$TMPFILE"
            mv "$TMPFILE" "$SUNTIMES_CACHE"
        else
            # Fallback values if API fails (no twilight ramp, instant switch)
            SUNRISE_HOUR=7
            SUNRISE_MIN=00
            SUNSET_HOUR=17
            SUNSET_MIN=00
            DAWN_HOUR=$SUNRISE_HOUR
            DAWN_MIN=$SUNRISE_MIN
            DUSK_HOUR=$SUNSET_HOUR
            DUSK_MIN=$SUNSET_MIN
        fi
    ) 9>"$SUNTIMES_LOCK"

    # Re-read cache after lock block (may have been written by this or another instance)
    if [ -f "$SUNTIMES_CACHE" ]; then
        SUNRISE_TIME=$(sed -n '2p' "$SUNTIMES_CACHE")
        SUNSET_TIME=$(sed -n '3p' "$SUNTIMES_CACHE")
        DAWN_TIME=$(sed -n '4p' "$SUNTIMES_CACHE")
        DUSK_TIME=$(sed -n '5p' "$SUNTIMES_CACHE")
        SUNRISE_HOUR=${SUNRISE_TIME%:*}
        SUNRISE_MIN=${SUNRISE_TIME#*:}
        SUNSET_HOUR=${SUNSET_TIME%:*}
        SUNSET_MIN=${SUNSET_TIME#*:}
        DAWN_HOUR=${DAWN_TIME%:*}
        DAWN_MIN=${DAWN_TIME#*:}
        DUSK_HOUR=${DUSK_TIME%:*}
        DUSK_MIN=${DUSK_TIME#*:}
    fi
fi

CURRENT_TIME=$(date +%H:%M)
CURRENT_MINUTES=$((10#${CURRENT_TIME%:*} * 60 + 10#${CURRENT_TIME#*:}))
SUNRISE_MINUTES=$((10#$SUNRISE_HOUR * 60 + 10#$SUNRISE_MIN))
SUNSET_MINUTES=$((10#$SUNSET_HOUR * 60 + 10#$SUNSET_MIN - 15))  # 15 min avant le coucher
DAWN_MINUTES=$((10#$DAWN_HOUR * 60 + 10#$DAWN_MIN))
DUSK_MINUTES=$((10#$DUSK_HOUR * 60 + 10#$DUSK_MIN))
SUNRISE_ACTUAL_MINUTES=$((10#$SUNRISE_HOUR * 60 + 10#$SUNRISE_MIN))
SUNSET_ACTUAL_MINUTES=$((10#$SUNSET_HOUR * 60 + 10#$SUNSET_MIN))

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

# Compute target brightness: 100 during the day, 70 at night, ramped
# smoothly across each civil twilight window (dawn->sunrise, sunset->dusk).
if [ "$CURRENT_MINUTES" -ge "$SUNRISE_ACTUAL_MINUTES" ] && [ "$CURRENT_MINUTES" -lt "$SUNSET_ACTUAL_MINUTES" ]; then
    TARGET_BRIGHTNESS=$DAY_BRIGHTNESS
elif [ "$CURRENT_MINUTES" -ge "$DAWN_MINUTES" ] && [ "$CURRENT_MINUTES" -lt "$SUNRISE_ACTUAL_MINUTES" ]; then
    SPAN=$((SUNRISE_ACTUAL_MINUTES - DAWN_MINUTES))
    [ "$SPAN" -le 0 ] && SPAN=1
    POS=$((CURRENT_MINUTES - DAWN_MINUTES))
    TARGET_BRIGHTNESS=$((NIGHT_BRIGHTNESS + (DAY_BRIGHTNESS - NIGHT_BRIGHTNESS) * POS / SPAN))
elif [ "$CURRENT_MINUTES" -ge "$SUNSET_ACTUAL_MINUTES" ] && [ "$CURRENT_MINUTES" -lt "$DUSK_MINUTES" ]; then
    SPAN=$((DUSK_MINUTES - SUNSET_ACTUAL_MINUTES))
    [ "$SPAN" -le 0 ] && SPAN=1
    POS=$((CURRENT_MINUTES - SUNSET_ACTUAL_MINUTES))
    TARGET_BRIGHTNESS=$((DAY_BRIGHTNESS - (DAY_BRIGHTNESS - NIGHT_BRIGHTNESS) * POS / SPAN))
else
    TARGET_BRIGHTNESS=$NIGHT_BRIGHTNESS
fi

# Only call ddcutil (slow, flaky over HDMI) when the target actually changed
LAST_BRIGHTNESS=$(cat "$BRIGHTNESS_STATE_FILE" 2>/dev/null || echo "")
if [ "$TARGET_BRIGHTNESS" != "$LAST_BRIGHTNESS" ]; then
    if "$SET_BRIGHTNESS" "$TARGET_BRIGHTNESS" 2>/dev/null; then
        echo "$TARGET_BRIGHTNESS" > "$BRIGHTNESS_STATE_FILE"
    fi
fi
