# setup this linuxconf on fresh-installed archlinux
# TODO: this linuxconf is not completed at all. lc_init to be filled (in future...)

lc_include arch-common/* utils/arch-virt.sh

lc_assert_user_is root
lc_fsmap hms/nginx.conf /etc/nginx/nginx.conf
lc_fsmap hms/exports /etc/exports
export PATH="$PATH:files/mybin"

function install_x86_gzip_bin () {
    binname="$1"
    link="$2"
    if [[ "$(uname -i)" = x86_64 ]] || [[ "$(uname -m)" = x86_64 ]]; then
        wget "$link" -O - | gzip -d > /tmp/.out && chmod +x /tmp/.out && mv /tmp/.out /usr/bin/$binname &&
        echo "******** $binname setup done." || echo "******** failed to setup $binname."
    else
        echo "******** skip $binname setup for non-x64 architecture."
    fi
}
lc_init () {
    pacman -Sy --needed --noconfirm cronie nginx docker dhcpcd ntp sshpass curl
    systemctl enable cronie nginx docker dhcpcd --now
    curl https://recolic.net/setup/ | l=1 bash

    echo "=====================
TODO: manual steps

#######################################################
#### Setup this server from stretch
# 1. Clean-Installed archlinux
# 2. dhcpcd patch: add 'allowinterfaces enp4s0f1' to /etc/dhdpcd.conf
# 3. Setup everything in OTHER SERVICE LIST.
# 4. linuxconf register
################## OTHER SERVICE LIST #################
# zfs/zpool setup
# docker (systemd) for jenserat/samba-publicshare, hms-sms-and-door-api
# fancontrol (systemd) for /sys/devices/platform/nct6775.2592/hwmon/hwmon2/pwm2_enable automodify
# dhcpcd (systemd):
#   modify /etc/dhcpcd.conf to set allowinterfaces to ETHERNET
#
## python telegram bot:
# pip install python-telegram setuptools --break-system-packages
# pacman -S openssl-1.1 # used by python-telegram
## telegram bots: need manual login

## zfs setup
# pkgs for zfs: zfs-linux-lts (https://wiki.archlinux.org/title/Unofficial_user_repositories#archzfs)
# check: /etc/module.load.d should contain zfs
# systemctl enable zfs-import-cache
# systemctl enable zfs-import.target
# systemctl enable zfs-mount
# systemctl enable zfs.target
# use 'zpool import xxx' and 'zfs mount xxx' to import & mount for the first time.
# zpool set autotrim=on nas-data-raid

## smb manual setup: 
# recolic.net/s/notebook
# with password: (genpasswd random.asd9vjd)

#######################
# all service require the storage disk:
# KVM and webvirtmgr; btsync; nfs; nginx
================"
}

lc_startup () {
    # Send a bootup message
    beep -f 950 -l 100 -r 2
    
    # swap
    swapon /dev/disk/by-id/nvme-SAMSUNG_MZVLW256HEHP-000L7_S35ENX0K430762-part2
    
    # nfs fix
    exportfs -arv
    
    echo "### Managed by linuxconf DO NOT MODIFY !!!
18 2 2 1 * $(pwd)/hms/cron_snapshot_zfs.fish annually
12 1 1 * * $(pwd)/hms/cron_snapshot_zfs.fish monthly
8 0 * * *  $(pwd)/hms/cron_snapshot_zfs.fish daily
" | crontab -

    # DDNS, ipv4 only
    lc_bgrun /var/log/ddns-daemon.log every 10m bash hms/ddns_once.sh
    # lc_bgrun /var/log/ddns-daemon.log every 10m curl -s "https://dynamicdns.park-your-domain.com/update?host=rhome&domain=896444.xyz&password=$(rsec DDNS_XYZ_TOKEN)"
    
    # frpc
    lc_bgrun /var/log/frpc1.log auto_restart frpc tcp -n hms_ssh  -l 22 -r 30512 -s proxy-cdn.recolic.net -P 30999 --token $(rsec FRP_KEY)
    lc_bgrun /var/log/frpc2.log auto_restart frpc tcp -n hms_http -l 80 -r 30513 -s proxy-cdn.recolic.net -P 30999 --token $(rsec FRP_KEY)
    
    # aria2 rpc
    lc_bgrun /var/log/aria2-rpcd.log bash -c "cd /mnt/fsdisk/nfs/pub/ && aria2c --enable-rpc --rpc-listen-all --rpc-allow-origin-all"
    
    # minecraft server
    lc_bgrun /var/log/launch-mcserver.log hms/launch-mcserver.fish
    
    # ZFS monitor
    lc_bgrun /var/log/recolic-zfs-monitor.log hms/zfs-monitor-failure-daemon.fish
    
    # naive file send server
    lc_bgrun /var/log/fserver.log python -u hms/fserver/hms-fserver.py
    
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

    subline=$(curl "$(rsec ProxySub_API)?3a" | base64 -d | grep C100.US1LW)
    lc_bgrun /var/log/v1080.log  go-shadowsocks2 -c "$subline" -socks :1080
    subline=$(curl "$(rsec ProxySub_API)?3a" | base64 -d | grep C100.JP2LW)
    lc_bgrun /var/log/v10808.log go-shadowsocks2 -c "$subline" -socks :10808

    lc_bgrun /dev/null fish hms/tfc-repomon.fish

    lc_bgrun /var/log/cron.log every 1d docker run --rm recolic/mailbox-cleaner imap.recolic.net tmp@recolic.net "$(rsec genpasswd_tmp@recolic.net)" -d 15
    # Using (rsec Telegram_API_HASH) (rsec Telegram_API_ID) (rsec PHONE)
    lc_bgrun /var/log/cron.log every 1d bash hms/telegram-public-msg-auto-cleanup/daily.sh
    lc_bgrun /var/log/cron.log bash hms/telegram-transcript/daemon.sh
    lc_bgrun /var/log/cron.log every 1d env suburl="$(rsec ProxySub_API)?1" fish hms/balancemon.fish
    lc_bgrun /var/log/cron.log every 1d ntpdate -u 1.pool.ntp.org
    lc_bgrun /var/log/cron.log every 1m env svm_workdir=/mnt/fsdisk/svm hms/vmm/cron-callback.sh
}




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

# # KMS server
# lc_bgrun /var/log/kms.log /root/linux-kms-server/vlmcsd/vlmcsd

## kvm setup
# pkgs for kvm: ebtables bridge-utils dnsmasq openbsd-netcat libvirt edk2-ovmf dmidecode
# services for kvm: virtlogd
# read recolic.net/s/notebook for kvm setup!

# Deprecated! Now we have simple-vmm # Setup bridge and then launch libvirtd
# /root/kvm-setup-bridge.sh
# lc_bgrun /var/log/libvirtd.log libvirtd --listen
# # Also prevent libvirt from LAN
# iptables -A INPUT -p tcp --dport 16509 -s 10.100.100.101 -j ACCEPT
# iptables -A INPUT -p tcp --dport 16509 -s 10.0.0.0/8 -j DROP

## nfs setup (deprecated 2025.7. remove in next setup)
# systemd: nfs service (deprecated)
# exportfs -arv
# systemctl enable nfsv4-server.service

#######################################################
##################     bug note    ####################
#######################################################

# after running for 139 days, clock have 2min31s error.


