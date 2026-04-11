#!/usr/bin/env bash

set -euo pipefail

make_bar() {
    local count=$1
    local char=$2
    local out=""

    while (( count > 0 )); do
        out+="$char"
        ((count--))
    done

    printf '%s' "$out"
}

if ! command -v pactl >/dev/null 2>&1; then
    printf '󰖀 sin audio\n'
    exit 0
fi

mute_state="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}')"
volume="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk 'NR==1 {gsub(/%/, "", $5); print $5}')"

if [[ -z "${volume:-}" ]]; then
    printf '󰖀 sin audio\n'
    exit 0
fi

if [[ "${mute_state:-no}" == "yes" ]]; then
    printf '󰝟 muted\n'
    exit 0
fi

filled=$(( volume / 10 ))
if (( filled > 10 )); then
    filled=10
fi

empty=$(( 10 - filled ))
printf '󰕾 %s%s %s%%\n' "$(make_bar "$filled" '▰')" "$(make_bar "$empty" '▱')" "$volume"
