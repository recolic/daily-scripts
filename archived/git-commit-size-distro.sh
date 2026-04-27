#!/usr/bin/env bash
# GPT 5.3

tmp=$(mktemp)

git rev-list --all | while read c; do
    git show "$c" --format= --patch | wc -c
done > "$tmp"

total=$(awk '{s+=$1} END{print s}' "$tmp")
count=$(wc -l < "$tmp")

p() {
    pct=$1
    awk -v p="$pct" -v n="$count" 'NR==int(n*p){print $1}' <(sort -n "$tmp")
}

echo "total_bytes=$total"
echo "P50_bytes=$(p 0.50)"
echo "P90_bytes=$(p 0.90)"
echo "P95_bytes=$(p 0.95)"
echo "P99_bytes=$(p 0.99)"

