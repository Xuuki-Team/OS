#!/bin/bash
# Simple weather check - shows rain status for today
# Uses wttr.in (no API key needed)

LOCATION="${1:-London}"
CACHE_FILE="$HOME/.cache/dwmblocks/weather"
CACHE_AGE=300  # 5 minutes

# Check cache first (if fresh)
if [ -f "$CACHE_FILE" ]; then
    CACHE_MTIME=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || stat -f %m "$CACHE_FILE" 2>/dev/null)
    if [ -n "$CACHE_MTIME" ]; then
        NOW=$(date +%s)
        AGE=$((NOW - CACHE_MTIME))
        if [ $AGE -lt $CACHE_AGE ]; then
            cat "$CACHE_FILE"
            exit 0
        fi
    fi
fi

# Fetch weather data (with timeout)
WEATHER=$(curl -s --max-time 10 "wttr.in/${LOCATION}?format=%C+%t" 2>/dev/null)

# Check for wttr.in rate limit / error messages
if [ -z "$WEATHER" ] || [ "${#WEATHER}" -lt 2 ] || [ "${#WEATHER}" -gt 100 ] || echo "$WEATHER" | grep -qiE "sorry|error|unknown|location|processed|rate|limit|follow|html|script"; then
    # Try cache even if old
    if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
        cat "$CACHE_FILE"
    else
        echo "󰖐 --"  # no data
    fi
    exit 0
fi

# Clean up the output
WEATHER=$(echo "$WEATHER" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

# Determine icon based on condition
ICON="󰖐"  # default cloudy
WEATHER_LOWER=$(echo "$WEATHER" | tr '[:upper:]' '[:lower:]')

# Rain / wet conditions
if echo "$WEATHER_LOWER" | grep -qiE "rain|shower|drizzle|thunder|precipitation|wet|humid"; then
    ICON="󰖗"  # umbrella
# Cloudy / grey conditions  
elif echo "$WEATHER_LOWER" | grep -qiE "cloud|overcast|fog|mist|haze|grey|gray|dull"; then
    ICON="󰖐"  # cloudy
# Snow / ice
elif echo "$WEATHER_LOWER" | grep -qiE "snow|sleet|ice|frost|freezing|blizzard"; then
    ICON="󰖘"  # snow
# Sun / clear
elif echo "$WEATHER_LOWER" | grep -qiE "sun|clear|sunny|bright|fair"; then
    ICON="󰖙"  # sunny
# Partly cloudy
elif echo "$WEATHER_LOWER" | grep -qiE "partly"; then
    ICON="󰖕"  # partly cloudy
# Windy
elif echo "$WEATHER_LOWER" | grep -qiE "wind|breezy|gale|storm"; then
    ICON="󰖝"  # windy
fi

# Format output: icon + weather description
OUTPUT="$WEATHER $ICON"
echo "$OUTPUT" | tr -d '\n'  # ensure no newlines

# Cache for next time
mkdir -p "$HOME/.cache/dwmblocks"
echo "$OUTPUT" > "$CACHE_FILE"
