lc_assert_user_is root

lc_init () {
    # basic pkg and config
    pacman -Syu --noconfirm fish dhcpcd vim sudo openssh git inetutils wget htop tmux
    pacman -S --noconfirm --asdeps openssl

    grep kernel.sysrq=1 /etc/sysctl.d/99-sysctl.conf > /dev/null || echo 'kernel.sysrq=1' >> /etc/sysctl.d/99-sysctl.conf

    grep recolic-aur /etc/pacman.conf || echo '[recolic-aur]
SigLevel = Optional TrustAll
Server = https://drive.recolic.cc/mirrors/recolic-aur' >> /etc/pacman.conf
    sed -i 's/^[# ]*ParallelDownloads *=[ 0-9A-Za-z]*$/ParallelDownloads = 5/' /etc/pacman.conf
    sed -i 's/^[# ]*IgnorePkg *=[ 0-9A-Za-z]*$/IgnorePkg = tpm2-tss microsoft-edge-stable-bin clion clion-jre/' /etc/pacman.conf
    sed -i 's/^[# ]*SystemMaxUse=[ 0-9A-Za-z]*$/SystemMaxUse=150M/g' /etc/systemd/journald.conf
    sed -i 's/^[# ]*SystemMaxFileSize=[ 0-9A-Za-z]*$/SystemMaxFileSize=30M/g' /etc/systemd/journald.conf
}

lc_startup () {
    iptables-restore  < files/iptables.rules
    ip6tables-restore < files/ip6tables.rules
    
    sysctl kernel.sysrq=1

    # wait for Internet
    while true; do
      ping -c 1 cloudflare.com && break ; sleep 2
    done

    local ips="$(ip a | grep inet | grep global | sed 's/^ *//g' | cut -d ' ' -f 2 | paste -sd' ' -)"
    curl 'https://recolic.net/api/cloudlog.php' --data "lc.arch-common Powered up $(uname -a), IP $ips"
}

