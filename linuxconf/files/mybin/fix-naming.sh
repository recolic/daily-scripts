#!/bin/bash

function fuck_sym () {
while true; do
    rename "$1" _ * || break
done
}
function clean_ad() {
  local name="$1"
  local tld="$2"
  if [[ "$name" =~ 【.*$tld.*】 ]]; then
      local nname=`echo "$name" | sed -E "s/【[^【】]*$tld[^【】]*】//g"`

     [[ "$nname" == -* ]] && nname="_${nname#-}"
     echo "DEBUG: mv $name $nname"
     mv -- "$name" "$nname"
  fi
}
function name_cleanup() {
    clean_ad "$1" com
    clean_ad "$1" club
    clean_ad "$1" xyz
}

# remove all leading '-'
for fl in -*; do
    rename -- - _ "$fl" # only once
done

# remove all these special chars
fuck_sym ' '
fuck_sym '('
fuck_sym ')'
fuck_sym '['
fuck_sym ']'
fuck_sym '"'
fuck_sym "'"

for fl in *; do
    name_cleanup "$fl"
done

