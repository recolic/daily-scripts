# setup this linuxconf on fresh-installed archlinux
# TODO: this linuxconf is not completed at all. lc_init to be filled (in future...)

lc_include arch-common/* utils/arch-virt.sh

lc_assert_user_is root

lc_init () {
    pacman -Sy --needed --noconfirm cronie
    systemctl enable cronie --now
}

lc_startup () {
# Send a bootup message
beep -f 950 -l 100 -r 2

# swap
swapon /dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K430762-part2

# nfs fix
exportfs -arv

iptables -I INPUT -s 10.100.100.0/24 -j ACCEPT

echo "### Managed by linuxconf DO NOT MODIFY !!!
18 2 2 1 * /root/cron_snapshot_zfs.fish annually
12 1 1 * * /root/cron_snapshot_zfs.fish monthly
8 0 * * * /root/cron_snapshot_zfs.fish daily
" | crontab -

lc_bgrun /var/log/ddns-daemon.log /root/ddns-daemon.sh

# frpc
lc_bgrun /var/log/frpc.log auto_restart frpc -c /root/frpc.ini

# aria2 rpc
lc_bgrun /var/log/aria2-rpcd.log bash -c "cd /mnt/fsdisk/nfs/pub/ && aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all"

# minecraft server
lc_bgrun /var/log/launch-mcserver.log /root/launch-mcserver.fish

# ZFS monitor
lc_bgrun /var/log/recolic-zfs-monitor.log /root/zfs-monitor-failure-daemon.fish

# SAW file send server
lc_bgrun /var/log/saw-fsend.log python -u /root/saw-fsend/hms-fserver.py

# extra iptables rules
iptables  -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT
iptables  -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables  -I INPUT -s 10.0.0.0/8 -j ACCEPT
iptables  -I INPUT -s 172.16.0.0/12 -j ACCEPT
iptables  -I INPUT -s 192.168.0.0/16 -j ACCEPT
ip6tables -I INPUT -p tcp -m tcp --dport 22 -j ACCEPT
ip6tables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
ip6tables -I INPUT -s fc00::/7 -j ACCEPT

# All services above should not fail without Internet.
######## Barrier: Wait for network up #########
while true; do                                #
  ping -c 1 cloudflare.com && break           #
  sleep 2                                     #
done                                          #
######## Barrier END: Wait for network up #####

lc_bgrun /var/log/v1080.log  /root/proxy.fish /root/comm100-nodes/COMM100LW-US9.json 1080
lc_bgrun /var/log/v10808.log /root/proxy.fish /root/comm100-nodes/COMM100LW-JP2.json 10808

lc_bgrun /dev/null fish /root/tfc-repomon.fish

lc_bgrun /var/log/cron.log every 1d docker run --rm recolic/mailbox-cleaner imap.recolic.net tmp@recolic.net $(cat files/secrets/hms-mail-pass.txt) -d 15
lc_bgrun /var/log/cron.log every 1d bash /root/telegram-public-msg-auto-cleanup/daily.sh
lc_bgrun /var/log/cron.log every 1d fish /root/balancemon.fish
lc_bgrun /var/log/cron.log every 1d ntpdate -u 1.pool.ntp.org
lc_bgrun /var/log/cron.log every 1m env svm_workdir=/mnt/fsdisk/svm /root/simple-vm-manager/cron-callback.sh
}

################## OTHER SERVICE LIST #################
# nginx (systemd) at 80
# nfs (systemd)
# docker (systemd) for jenserat/samba-publicshare, webvirtmgr(deprecated), hms-sms-and-door-api
# fancontrol (systemd) for /sys/devices/platform/nct6775.2592/hwmon/hwmon2/pwm2_enable automodify
# webvirtmgr, webvirtmgr-console (docker), refer to recolic.net/s/notebook
# openvpn server (docker)
# cronie (systemd):
#   ref ~/cron-backups.log.gz
# dhcpcd (systemd):
#   modify /etc/dhcpcd.conf to set allowinterfaces to ETHERNET

## many python scripts running on this server
# pip install python-telegram mailbox_cleaner setuptools --break-system-packages
# pacman -S openssl-1.1 # used by python-telegram

# before starting services, ln these conf
# ln -s /root/etc-conf/exports /etc/exports
# ln -s /root/etc-conf/nginx.conf /etc/nginx/nginx.conf

## zfs setup
# pkgs for zfs: zfs-linux-lts (https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs)
# check: /etc/module.load.d should contain zfs
# systemctl enable zfs-import-cache
# systemctl enable zfs-import.target
# systemctl enable zfs-mount
# systemctl enable zfs.target
# use `zpool import xxx` and `zfs mount xxx` to import & mount for the first time.
# zpool set autotrim=on nas-data-raid

## nfs setup
# exportfs -arv
# systemctl enable nfsv4-server.service

## kvm setup
# pkgs for kvm: ebtables bridge-utils dnsmasq openbsd-netcat libvirt edk2-ovmf dmidecode
# services for kvm: virtlogd
# read recolic.net/s/notebook for kvm setup!

#######################
# all service require the storage disk:
# KVM and webvirtmgr; btsync; nfs; nginx

#######################################################
#### Setup this server from stretch
# 1. Clean-Installed archlinux
# 2. Install extra packages [see below list], and enable services.
# 3. dhcpcd patch: add `allowinterfaces enp4s0f1` to /etc/dhdpcd.conf
# 4. Setup everything in OTHER SERVICE LIST.
#
# pacman packages list: dhcpcd vim v2ray ntp android-tools




####################################################### ####################################################################
##################       STOP       ###################
#######################################################
################## Deprecated notes ###################
#######################################################

# docker (systemd) for adb-web (deprecated at 2022.9.1)
# android_web (docker) (deprecated at 2022.9.1)
# btsync (systemd, from aur, deprecated at 2023.4.7)

## genymotion setup [deprecated at 2022.9.1]
# Run setup-genymotion-archlinux-manual.sh in `~/sh`

## [deprecated] web virtualbox NOTE:
# MUST re-configure php with this guide: https://wiki.archlinux.org/index.php/PhpVirtualBox#VirtualBox_web_service

## cups setup (hp1020) [deprecated at 2023.4.1, using new HP wireless printer]
# pkgs for printing: nss-mdns, cups, avahi. IgnorePkg: cups=2.3.3-3, cups-filters=1.28.5-1, libcups=2.3.3-3
# systemctl enable cups.service
# systemctl enable avahi-daemon.service
## manual bug fix: ln -s libldap.so libldap-2.4.so.2

# # restart smbd api interface
# lc_bgrun /dev/null bash /root/restart-smbd-apid.sh 30411

#######################################################
##################     bug note    ####################
#######################################################

# after running for 139 days, clock have 2min31s error.

#######################################################
################## Deprecated cmds ####################
#######################################################

# # mount unreliable storage
# mount --uuid 6ec547a1-b779-494b-822f-a2aaa0b56bd0 /mnt/fsdisk/nfs/pub/unreliable_mnt

# # KMS server
# lc_bgrun /var/log/kms.log /root/linux-kms-server/vlmcsd/vlmcsd

# frp server: closed. proxy-cdn.recolic.net provided by vultr
# lc_bgrun /var/log/frps.log frps -c /root/frps.ini

# Deprecated! Now we have simple-vmm # Setup bridge and then launch libvirtd
# /root/kvm-setup-bridge.sh
# lc_bgrun /var/log/libvirtd.log libvirtd --listen
# # Also prevent libvirt from LAN
# iptables -A INPUT -p tcp --dport 16509 -s 10.100.100.101 -j ACCEPT
# iptables -A INPUT -p tcp --dport 16509 -s 10.0.0.0/8 -j DROP

# Prevent ladlod router from accessing NFS.
#iptables -A INPUT --dport  2049 -s 10.100.100.122 -j DROP
#iptables -A INPUT --dport   111 -s 10.100.100.122 -j DROP

# lc_bgrun /var/log/polipo.log polipo -c /root/polipo.config
# lc_bgrun /var/log/miner-tcp-forward.log proxychains socat TCP-LISTEN:30955,fork,reuseaddr TCP:asia1.ethermine.org:4444

# IPLC OpenVPN online, udp2raw not required anymore.
# lc_bgrun /dev/null udp2raw -c -l 0.0.0.0:1199 -r 102.140.91.35:587 -k rtlgn24bgn --raw-mode icmp -a

# lc_bgrun /dev/null docker start river-test-machine

# disabled # Genymotion VNC
# lc_bgrun /dev/null socat tcp-listen:5903,fork,reuseaddr tcp:localhost:5902
# # Also use proxy: docker run -d --restart=always --name novnc -p 6089:6080 -e AUTOCONNECT=true -e VNC_PASSWORD=rtlgn24bgn -e VNC_SERVER=172.17.0.1:5903 -e VIEW_ONLY=false bonigarcia/novnc:1.1.0

# lc_bgrun /var/log/uploader.log bash -c 'cd /root/nfs/pub/tmp && python SimpleHTTPServerWithUpload.py'

# # NTP, required by v2ray, now executed by cronie
# lc_bgrun /var/log/ntpdate.log ntpdate -u 1.pool.ntp.org

# # msauth VM will be started by simple-vmm. now running on ms.recolic
# lc_bgrun /var/log/msauth-httpd.log /root/msauth-httpd
# email_notify "HMS rebooted. Please VNC to hms.re:5918 to start Microsoft Auth app."

