#!/bin/bash
# this script modifies itself with latest "touch time"
tmpf=`mktemp` &&
cat "$0" | grep -v '^##' > "$tmpf" &&
echo -n '##' >> "$tmpf" &&
date >> "$tmpf" &&
mv "$tmpf" "$0" &&
chmod +x "$0" ||
echo "Failed to touch"

# Last touched at:
##Thu Jul 27 04:17:43 PM PDT 2023
