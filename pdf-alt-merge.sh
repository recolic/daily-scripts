#!/bin/bash
# help merge single-sided scanner result.

# Input files
ODD_PDF="$1" # 1 3 5 7 9
EVEN_PDF="$2" # 10 8 6 4 2
OUTPUT_PDF="merged.pdf"

[ "$EVEN_PDF" = "" ] && echo "usage: $0 odd.pdf even.pdf" && exit 1

# Count pages (should be equal)
ODD_COUNT=$(pdftk "$ODD_PDF" dump_data | grep NumberOfPages | awk '{print $2}')
EVEN_COUNT=$(pdftk "$EVEN_PDF" dump_data | grep NumberOfPages | awk '{print $2}')

if [ "$ODD_COUNT" -ne "$EVEN_COUNT" ]; then
    echo "Error: Odd and Even PDFs do not have the same number of pages."
    exit 1
fi

# Reverse even pages to get correct order
pdftk "$EVEN_PDF" cat end-1 output even_reversed.pdf

# Merge by interleaving (shuffle) pages
pdftk A="$ODD_PDF" B=even_reversed.pdf shuffle A1-"$ODD_COUNT" B1-"$EVEN_COUNT" output "$OUTPUT_PDF"

# Clean up
rm even_reversed.pdf

echo "Merged PDF created: $OUTPUT_PDF"


