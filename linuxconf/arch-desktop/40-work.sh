lc_startup () {
    if [ "$(whoami)" = root ]; then
        # We need this fix if we are hacking /etc/os-release and pretending debian. 
        [[ -f /usr/bin/dkms ]] && sed -i 's/sign_file=[^ ]*$/sign_file=fuckyouidiot /g' /usr/bin/dkms
        
        # Microsoft Edge fix
        if [ -f /usr/share/applications/microsoft-edge.desktop ]; then
          if ! grep disable-features=msUndersideButton /usr/share/applications/microsoft-edge.desktop; then
            sed -i 's/.usr.bin.microsoft-edge-stable/& --disable-features=msUndersideButton --gtk-version=3/' /usr/share/applications/microsoft-edge.desktop
          fi  
        fi  

        # Azure VPN fix
        if [ -f /usr/share/polkit-1/rules.d/microsoft-azurevpnclient.rules ]; then
            if ! grep "action.id.indexOf" /usr/share/polkit-1/rules.d/microsoft-azurevpnclient.rules; then
                echo cG9sa2l0LmFkZFJ1bGUoZnVuY3Rpb24oYWN0aW9uLCBzdWJqZWN0KSB7CiAgICBpZiAoYWN0aW9uLmlkLmluZGV4T2YoIm9yZy5mcmVlZGVza3RvcC5yZXNvbHZlMSIpID49IDApIHtyZXR1cm4gcG9sa2l0LlJlc3VsdC5ZRVM7fQp9KTsK | base64 -d >> /usr/share/polkit-1/rules.d/microsoft-azurevpnclient.rules
            fi
        fi

        # Both Azure-VPN and GlobalProtect use systemd-resolved. This one won't break NetworkManager.
        ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

        # Don't pollute my app search
        [ -f /usr/share/applications/firefox-developer-edition.desktop ] && sed -i 's/Edition//g' /usr/share/applications/firefox-developer-edition.desktop

        lc_bgrun /var/log/mspc_switch.log every 60s bash files/etc-hosts-auto-switch.sh
    else
        # lc_bgrun /dev/null every 30m /etc/ar2/ar2.sh

        # azure-cli login fix
        [[ -f /usr/bin/az ]] && az config set core.login_experience_v2=off
    fi
}

lc_fsmap /home/recolic/code/msdoc/proj/mymsbin /usr/mymsbin
lc_fsmap "$HOME/sh/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

lc_init () {
    if [ "$(whoami)" = root ]; then
        pacman -S --noconfirm mdatp-bin intune-portal-bin microsoft-azure-vpn-client-bin globalprotect-openconnect code azure-cli
        systemctl enable systemd-resolved # for azure-vpn
        systemctl enable mdatp

        lc_todo "yay -S --noconfirm aur/microsoft-edge-stable-bin aur/powershell-lts-bin"
        lc_todo "sudo pacman -U https://recolic.net/hms?/softwares/clion2023/clion-1%3A2023.3.6-1-x86_64.pkg.tar.zst"
        lc_todo "sudo pacman -U https://recolic.net/hms?/softwares/clion2023/clion-jre-1%3A2023.3.6-1-x86_64.pkg.tar.zst"
    else
        env install=1 /usr/mymsbin/browser-wrapper.sh

        lc_todo "setup microsoft intune"
        lc_todo "[azvpn] add user to 'network' group"
    fi
}

lc_login () {
    lc_assert_user_is_not root

    if ! grep -F .m.recolic /etc/hosts > /dev/null; then
        gpg -d -o /tmp/.hosts.tmp secrets/work-hosts.gpg && sudo mv /tmp/.hosts.tmp /etc/hosts
    fi

    if [ ! -f "$HOME/.cache/git-work-config.inc" ]; then
        echo -e "[user]\nname = Benson\nemail = $(rsec MSID)" > "$HOME/.cache/git-work-config.inc"
        chmod 777 "$HOME/.cache/git-work-config.inc"
    fi
}
