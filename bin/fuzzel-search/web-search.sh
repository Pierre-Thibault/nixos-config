#!/usr/bin/env bash
# Generic web search script using fuzzel
# Usage: web-search.sh "Search Name" "https://example.com/search?q="

SEARCH_NAME="$1"
SEARCH_URL="$2"

if [ -z "$SEARCH_NAME" ] || [ -z "$SEARCH_URL" ]; then
    echo "Usage: $0 'Search Name' 'https://example.com/search?q='"
    exit 1
fi

# Use fuzzel to get search query (free text input)
QUERY=$(fuzzel --dmenu --prompt="$SEARCH_NAME: " --width=60 --lines=0 < /dev/null)

# Exit if user cancelled (empty query)
if [ -z "$QUERY" ]; then
    exit 0
fi

# URL encode the query using jq
ENCODED_QUERY=$(jq -rn --arg str "$QUERY" '$str | @uri')

# Open browser with search URL (detached from current process)
setsid -f flatpak run net.waterfox.waterfox --new-tab "${SEARCH_URL}${ENCODED_QUERY}" >/dev/null 2>&1
