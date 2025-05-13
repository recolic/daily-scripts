

#############################
# setup from archlinux
pacman -S tigervnc virtualbox lxqt ttf-dejavu linux-lts-headers

########### NOW run as user recolic #############
vncpasswd # MANUAL
echo '
session=lxqt
geometry=1920x1080
localhost
alwaysshared
' > ~/.vnc/config

########### NOW run as user root #############
echo ":2=recolic" >> /etc/tigervnc/vncserver.users
systemctl enable vncserver@:2.service --now
echo 'nohup "socat tcp-listen:5903,fork,reuseaddr tcp:localhost:5902" & disown' >> /etc/rc.local
nohup "socat tcp-listen:5903,fork,reuseaddr tcp:localhost:5902" & disown

export http_proxy=http://10.100.100.101:3128
export https_proxy=http://10.100.100.101:3128
curl https://dl.genymotion.com/releases/genymotion-3.2.1/genymotion-3.2.1-linux_x64.bin -o g.bin &&
chmod +x g.bin &&
./g.bin &&
rm g.bin


