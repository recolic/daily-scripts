#!/bin/bash
declare -a farr
farr=($(ls *.php))
for fpath in "${farr[@]}" 
do
	:
	if file --mime-encoding $fpath | grep 'iso-8859-1'; then
		echo "Converting $fpath ..."
	else
		echo "Refused: $fpath"
		continue
	fi
	if iconv -f "GB18030" -t "UTF-8" $fpath -o $fpath; then
		echo "Done."
	else
		echo "(At $fpath)"
	fi
done
echo "Finished!"

