#!/bin/bash
# run this bash script in an empty dir
# supported pdf reader: evince (tested good)
set -e

echo "** will download army recipe to current dir"

mkdir -p index && cd index
wget https://quartermaster.army.mil/jccoe/publications/recipes/index/full_index.pdf

pdftk full_index.pdf output uncompressed.pdf uncompress
grep -a -oP '/F\s*\(\K[^)]+(?=\))' uncompressed.pdf | sort | uniq > links.txt

echo "** manual check 'links.txt' before continue the following script. PRESS ENTER if looks good"
echo "** should contain section_index.pdf and every recipe PDF"
read -r _tmp

prefix="https://quartermaster.army.mil/jccoe/publications/recipes/index"
while read -r p; do
  echo "DEBUG: download $p"
  mkdir -p "$(dirname "$p")"
  wget -q -O "$p" "$prefix/$p" || echo "$(basename "$p") download failed" >> error.log
done < links.txt

