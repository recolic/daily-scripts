#!/bin/bash
echo "Warning: this script has been replaced by unzip-iconv"
LANG=C /usr/bin/7z x -y "$1" | sed -n 's/^Extracting //p' | sed '1!G;h;$!d' | xargs convmv -f gbk -t utf8 --notest >/dev/null 2>/dev/null
