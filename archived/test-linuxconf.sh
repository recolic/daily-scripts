set -e
cd ~/Nextcloud
tar -cvzf /tmp/test.lc lc.desktop/
netpush /tmp/test.lc
#tar -cvzf /tmp/test.tgz examples
#netpush /tmp/test.tgz linuxconf

echo "
TEST >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
rm /mnt/fsdisk/svm/vm/archtest/ -r
pgkill archtest

ssh -p 30476  r@hms.r
TEST MSPC >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

sudo su

cd /
curl https://recolic.cc/tmp/test.tgz | tar xvzf -
cd examples/archlinux-gnome/
./linuxconf.wrapper register masterconf.sh
"

echo "
TEST MSPC >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
rm -r /extradisk/simple-vm-manager/data/vm/archtest/
pgkill archtest

rm ~/.ssh/known_hosts ; ssh -p 30478  r@localhost

sudo su

cd /
curl https://recolic.cc/tmp/test.lc | tar xvzf -
cd lc.desktop/
pacman -Sy archlinux-keyring && 
./linuxconf.wrapper register masterconf.sh
"
