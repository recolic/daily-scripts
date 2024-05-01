#!/bin/bash
[ "$1" = "" ] && echo "Usage: $0 <alliant.csv>" && exit 1
expr_=`cat "$1" | sed 's/\$0.00/NUL/g' | # strip 0.00 fees
    sed -E 's/\(\$([0-9]*\.[0-9][0-9])\)/$-\1/g' | # replace ($1.11) to $-1.11
    grep -o '\$[0-9-]*\.[0-9][0-9]' | # grep all price tags
    tr -d '$' | # remove leading dollar sign
    tr '\n' '+' | # join strings
    sed 's/+$//' # remove tail plus sign
`
res=`python -c "print('%.2f' %  ($expr_)  )"`

echo "$expr_ = $res"
