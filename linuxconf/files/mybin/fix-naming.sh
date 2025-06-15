#!/bin/bash

function fuck_sym () {
while true; do
    rename "$1" _ * || break
done
}
function name_cleanup() {
  local name="$1"
  if [[ "$name" =~ 【.*com.*】 ]]; then
      local nname=`echo "$name" | sed -E 's/【[^【】]*com[^【】]*】//g'`

     [[ "$nname" == -* ]] && nname="_${nname#-}"
     echo "DEBUG: mv $name $nname"
     mv -- "$name" "$nname"
  fi
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

