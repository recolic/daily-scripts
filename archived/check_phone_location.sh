#!/usr/bin/bash

[[ $1 == '' ]] && echo 'Usage: get_phone_location.sh 13007151234' && exit 1
tmpfl=`mktemp`

for i in 1 .. 5
do
    curl "http://www.ip138.com:8080/search.asp?action=mobile&mobile=$1" 2>/dev/null | iconv -f "GB18030" -t "UTF-8" > $tmpfl
    failed=`grep '验证手机号有误' $tmpfl`
    res=`grep '</TD><td' $tmpfl | sed 's/^.*-->//g' | sed 's/<\/TD>//g' | sed 's/&nbsp;/ /g'`
    res2=`grep '<TD class="tdc2" align="center">' $tmpfl | sed 's/^.*er">//g' | sed 's/<\/TD>//g' | sed 's/&nbsp;/ /g'`
    res3=`grep ' align="center" class=tdc2>' $tmpfl | grep nbsp | sed 's/^.*tdc2>//g' | sed 's/<\/TD>//g' | sed 's/&nbsp;/ /g'`

    [[ $failed != '' ]] && break
    [[ $res != '' ]] && echo "$1 $res" && exit 0
    [[ $res2 != '' ]] && echo "$1 $res2" && exit 0
    [[ $res3 != '' ]] && echo "$1 $res3" && exit 0

#    echo "DEBUG Failed to handle>" && cat $tmpfl
    sleep 2 # Do not fuck ip138 too quickly...
done

echo "Failed to check phone number $1."
exit 2
