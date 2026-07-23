#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "$0")"
password="$(genpasswd recolic.net)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
files=()

download_matches() {
    local mailbox="$1" subject="$2" kind="$3" id rest file
    while IFS=$'\t' read -r id rest; do
        [[ "$id" =~ ^[0-9]+$ ]] || continue
        file="$tmp/$kind-$id"
        python imap-list-recent.py --password "$password" --mailbox "$mailbox" \
            --download "$id" imap.recolic.net root@recolic.net > "$file"
        files+=("$kind" "$file")
    done < <(python imap-list-recent.py --password "$password" --days 30 \
        --mailbox "$mailbox" --contains "$subject" imap.recolic.net root@recolic.net)
}

download_matches Junk 'Your credit card statement is available' boa
download_matches Junk 'Your Venture X Card statement is ready' c1
download_matches INBOX 'Your statement for credit card account' wf
download_matches INBOX 'Your automatic payment is scheduled for' bilt

python - "${files[@]}" <<'PY'
import html
import quopri
import re
import sys
from datetime import date, datetime, timedelta


def text(path):
    raw = open(path, "rb").read()
    decoded = quopri.decodestring(raw).decode("utf-8", "replace")
    decoded = html.unescape(re.sub(r"<[^>]*>", " ", decoded))
    return re.sub(r"\s+", " ", decoded)


def match(pattern, body, field):
    found = re.search(pattern, body, re.I)
    if not found:
        raise ValueError(f"cannot find {field}")
    return found.group(1)


def parse_date(value):
    value = value.rstrip(". ")
    for fmt in ("%B %d, %Y", "%m/%d/%Y"):
        try:
            return datetime.strptime(value, fmt).date()
        except ValueError:
            pass
    result = datetime.strptime(f"{value}, {date.today().year}", "%B %d, %Y").date()
    if result < date.today() - timedelta(days=45):
        result = result.replace(year=result.year + 1)
    return result


rows = []
for kind, path in zip(sys.argv[1::2], sys.argv[2::2]):
    body = text(path)
    try:
        if kind == "boa":
            card = match(r"Account\s+(.+? - \d{4})\s+Statement Date", body, "account")
            amount = match(r"Statement Balance\s+\$([\d,]+\.\d{2})", body, "balance")
            due = match(r"minimum payment of \$[\d,]+\.\d{2} is due on\s+([A-Z]+ \d{1,2}, \d{4})", body, "due date")
        elif kind == "c1":
            card = "Venture X " + match(r"Venture X Card ending in (\d{4})", body, "account")
            amount = match(r"Statement\s+balance:\s*\$([\d,]+\.\d{2})", body, "balance")
            due = match(r"Payment due\s+date:\s*([A-Z]+ \d{1,2}, \d{4})", body, "due date")
        elif kind == "wf":
            card = "Wells Fargo " + match(r"credit card account \.{3}(\d{4})", body, "account")
            amount = match(r"Statement balance:\s*\$([\d,]+\.\d{2})", body, "balance")
            due = match(r"Payment due date:\s*(\d{2}/\d{2}/\d{4})", body, "due date")
        else:
            card = "Bilt"
            amount = match(r"statement balance payment of \$([\d,]+\.\d{2})", body, "balance")
            due = match(r"will be made on ([A-Z]+ \d{1,2}(?:, \d{4})?)", body, "payment date")
        rows.append((parse_date(due), card, amount))
    except ValueError as error:
        raise SystemExit(f"{kind}: {error}")

print(f"{'DAY':<10}  {'CREDIT CARD':<42}  {'USD':>10}")
for due, card, amount in sorted(rows):
    print(f"{due.isoformat():<10}  {card:<42}  {amount:>10}")
PY
