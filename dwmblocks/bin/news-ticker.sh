#!/bin/bash
set -euo pipefail

NEWS_URL=${NEWS_URL:-"https://www.theguardian.com/uk/rss"}
NEWS_WIDTH=${NEWS_WIDTH:-42}
NEWS_DELAY=${NEWS_DELAY:-0.2}
NEWS_REFRESH=${NEWS_REFRESH:-1800}
NEWS_SIGNAL=${NEWS_SIGNAL:-5}
CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/dwmblocks
STATE_FILE="$CACHE_DIR/news"
ICON=${NEWS_ICON:-"  "}
ICON_BYTES=${#ICON}
if (( ICON_BYTES >= NEWS_WIDTH )); then
    TEXT_WIDTH=$NEWS_WIDTH
else
    TEXT_WIDTH=$((NEWS_WIDTH - ICON_BYTES))
fi

fetch_news() {
    curl -fsSL "$NEWS_URL" \
        | xmllint --xpath "//item/title/text()" - 2>/dev/null \
        | tr '\n' '  |  '
}

update_output() {
    local text="$1"
    mkdir -p "$CACHE_DIR"
    printf '%-*s%s' "$TEXT_WIDTH" "$text" "$ICON" >"$STATE_FILE"
    pkill -RTMIN+"$NEWS_SIGNAL" dwmblocks >/dev/null 2>&1 || true
}

main() {
    command -v curl >/dev/null 2>&1 || { printf 'curl missing\n' >&2; exit 1; }
    command -v xmllint >/dev/null 2>&1 || { printf 'xmllint missing\n' >&2; exit 1; }

    local news latest_update now substr
    news=$(fetch_news)
    latest_update=$(date +%s)

    while true; do
        local len=${#news}
        for ((i=0; i<len; i++)); do
            now=$(date +%s)
            if (( now - latest_update >= NEWS_REFRESH )); then
                news=$(fetch_news)
                latest_update=$now
                len=${#news}
                i=0
            fi

            substr=${news:$i:$TEXT_WIDTH}
            if [[ ${#substr} -lt $TEXT_WIDTH && $len -gt 0 ]]; then
                substr="$substr${news:0:$((TEXT_WIDTH - ${#substr}))}"
            fi

            update_output "$substr"
            sleep "$NEWS_DELAY"
        done
    done
}

main "$@"
