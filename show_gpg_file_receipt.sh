#!/bin/bash
# show gpg receipt

fname="$1"
[[ "$fname" = "" ]] && echo "Usage: $0 <file>" && exit 1
echo -n "$fname "
gpg --pinentry-mode cancel --list-packets "$fname" 2>&1 | grep keyid | sed 's/^.*keyid //g'
exit $?

## usage
# for fl in (find . -type f)
#     if file $fl | grep 'PGP message' > /dev/null
#         ~/sh/show_gpg_file_receipt.sh "$fl"
#     end
# end

