#!/bin/bash
# Usage: 1. Generate your key file, and keep it secret. Get its SHA256 and write it down at `answer`.
#        2. Compile runas.cc, Then run the following commands as root:
#               chmod +s ./runas
#        3. Try `./runas -k ./key` as normal user.
#
# File Permissions:
# 
# -rwsr-sr-x 1 root    root    82K Apr 18 19:29 runas*
# -rw-r--r-- 1 recolic recolic 320 Apr 18 19:29 runas.cc
# ---------- 1 root    root    733 Apr 18 19:35 runas.impl.sh*


[ "$1" = "" ] && key_file_name="./key" || key_file_name="$1"
echo "Verifying '$key_file_name'..."

#### Verify key file
checksum=$(sha256sum "$key_file_name" | sed 's/ .*$//g')
answer='07ecd901c90ee7a72efdc0d7e7b47c2b8d02b5a9cfcbb9ae4f0f31561d01af04'

if [ "$checksum" = "$answer" ]; then
	bash
else
	echo 'Verification failed.'
	exit 2
fi

exit $?

