#!/usr/bin/env bash
# created by GPT 6.1 sol
set -euo pipefail

if [[ $# -ne 1 || "$1" != *.md ]]; then
    printf 'Usage: %s xxx.md\n' "$0" >&2
    exit 2
fi

input="$(realpath -- "$1")"
output="${input%.md}.pdf"
html="$(mktemp --suffix=.html)"
trap 'rm -f -- "$html"' EXIT

python - "$input" "$html" <<'PY'
import pathlib
import sys
import markdown

source, target = map(pathlib.Path, sys.argv[1:])
body = markdown.markdown(source.read_text(encoding="utf-8"), extensions=["tables", "fenced_code"])
css = """
@page { size: A4; margin: 17mm; }
body { font: 10pt/1.45 Arial, sans-serif; color: #222; overflow-wrap: anywhere; }
h1, h2, h3 { break-after: avoid; }
h2 { font-size: 15pt; }
table { width: 100%; border-collapse: collapse; font-size: 8.5pt; }
th, td { border: 1px solid #bbb; padding: 5px; vertical-align: top; }
th { background: #eee; }
tr, pre { break-inside: avoid; }
pre { background: #f3f3f3; padding: 10px; white-space: pre-wrap; }
code { font-family: monospace; font-size: 0.9em; }
img { max-width: 100%; }
"""
import html
base = html.escape(source.parent.as_uri() + "/", quote=True)
target.write_text(f'<!doctype html><html><head><meta charset="utf-8"><base href="{base}"><style>{css}</style></head><body>{body}</body></html>', encoding="utf-8")
PY

chromium --headless --no-pdf-header-footer "--print-to-pdf=$output" "file://$html"
