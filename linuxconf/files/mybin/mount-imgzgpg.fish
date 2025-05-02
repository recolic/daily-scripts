#!/bin/fish

set fname $argv[1]
set mountp $argv[2]

test -z "$fname" ; or test -z "$mountp" ; and echo "Usage: this-script.fish path/to/site.imgz.gpg /mnt" ; and exit 1

set tmpdecoded /tmp/web-tmp-decoded(echo "$fname" | md5sum | cut -d ' ' -f 1)
gpg --decrypt $fname | gzip -d > $tmpdecoded ; or exit $status

# Let's mount
sudo mount -o loop $tmpdecoded $mountp ; or exit $status

echo "Mount $tmpdecoded to $mountp success. Waiting for unmount..."
while true
    sleep 5
    mount | grep -F "$tmpdecoded " > /dev/null ; or break
end

echo "Unmounted. saving and exit..."
gzip -c $tmpdecoded | gpg --encrypt --yes -r root@recolic.net -o $fname
set tmp_stat $status
rm -f $tmpdecoded
exit $tmp_stat



