#!/bin/bash
# do http request pass localhost:8123

if [ "$1" == "" ]; then
	echo 'Usage: byproxy <command>'
fi
export http_proxy='localhost:8123'
$*
RET_VAL=$?
export http_proxy=''
exit $RET_VAL
