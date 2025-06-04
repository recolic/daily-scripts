lc_assert_user_is root

lc_init () {
    # add primary user. If you want to do this, at least give read access to linuxconf dir.
    useradd --create-home --shell /usr/bin/fish recolic
    echo 'recolic ALL=(ALL) NOPASSWD: ALL' | EDITOR='tee -a' visudo
    # usermod --password $(echo testpass | openssl passwd -1 -stdin) recolic

    if ! sudo -u recolic realpath pc-mpc.sh; then
        echo "ERROR recolic do not have read access to current dir"
    else
        sudo -u recolic linuxconf register pc-mpc.sh
    fi

    pacman -Sy --needed --noconfirm gnome networkmanager power-profiles-daemon nextcloud-client firefox
    systemctl enable gdm NetworkManager power-profiles-daemon
    pacman -Sy --needed --noconfirm base-devel telegram-desktop docker shadowsocks-rust dos2unix v2ray proxychains xclip adobe-source-han-sans-cn-fonts      pcsclite ccid     ttf-fira-code  nfs-utils python-pip gnome-tweaks fcitx5-im man-db man-pages  kolourpaint breeze
    systemctl enable bluetooth pcscd

    #For GPG smartcard# sudo apt install pcscd scdaemon gnupg2 pcsc-tools -y

    pacman -Sy --needed --noconfirm recolic-aur/gnome-terminal-transparency recolic-aur/oreo-cursors-git

    lc_fsmap files/etc_environment /etc/environment
    lc_fsmap files/mybin /usr/mybin
}

