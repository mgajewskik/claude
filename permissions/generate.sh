#!/usr/bin/env bash
# Writes deny.txt / ask.txt into settings.json permissions.deny / permissions.ask.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
settings="${1:-$dir/../settings.json}"

# Each pattern X becomes Bash(X); unless X starts with `*`, also Bash(rtk X) and
# Bash(rtk * X) (rtk proxy/err/test/summary/run X), because deny rules only
# match the start of a command.
rules='split("\n")
  | map(select(length > 0 and (startswith("#") | not)))
  | map("Bash(" + . + ")")
    + (map(select(startswith("*") | not)) | map("Bash(rtk " + . + ")", "Bash(rtk * " + . + ")"))'

deny="$(jq -R -s "$rules" "$dir/deny.txt")"
ask="$(jq -R -s "$rules" "$dir/ask.txt")"

jq --argjson deny "$deny" --argjson ask "$ask" \
    '.permissions.deny = $deny | .permissions.ask = $ask' "$settings" >"$settings.tmp"
mv "$settings.tmp" "$settings"
