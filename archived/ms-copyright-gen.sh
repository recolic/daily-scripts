
[[ "$1" = "" ]] && echo "Usage: <this.sh> fname" && exit 1

ipath="$1"
bname=`basename "$ipath"`
tmppath="/tmp/.fgentmp-$bname"

abstract_txt="$bname"
author_txt1=`git log "$ipath" | grep '^Author: ' | tail -n1 | sed 's/^Author: *//g'`
author_txt2=`git log "$ipath" | grep '^Date: '   | tail -n1 | sed 's/^Date: *//g'`

echo "/*++

Copyright (c) Microsoft Corporation

Module Name:

    $bname

Abstract:

    $bname

Author:

    $author_txt1
    $author_txt2

--*/
" > "$tmppath"

cat "$ipath" >> "$tmppath"

mv -f "$tmppath" "$ipath"




