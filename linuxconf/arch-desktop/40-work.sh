lc_startup () {
    if [ "$(whoami)" = root ]; then
        lc_bgrun /dev/null every 1h systemctl restart microsoft-identity-device-broker.service
    
        # We need this fix if we are hacking /etc/os-release and pretending debian. 
        [[ -f /usr/bin/dkms ]] && sed -i 's/sign_file=[^ ]*$/sign_file=fuckyouidiot /g' /usr/bin/dkms
        
        # Microsoft Edge fix
        if [[ -f /usr/share/applications/microsoft-edge.desktop ]]; then
          if ! grep disable-features=msUndersideButton /usr/share/applications/microsoft-edge.desktop; then
            sed -i 's/.usr.bin.microsoft-edge-stable/& --disable-features=msUndersideButton/' /usr/share/applications/microsoft-edge.desktop
          fi  
        fi  
    else
        lc_bgrun /dev/null every 1h systemctl restart --user microsoft-identity-broker.service
        # lc_bgrun /dev/null every 30m /etc/ar2/ar2.sh

        # azure-cli login fix
        [[ -f /usr/bin/az ]] && az config set core.login_experience_v2=off
        
        if [ ! -f "$HOME/.cache/git-work-config.inc" ]; then
            echo W3VzZXJdCiAgICBuYW1lID0gQmVuc29uIExpdQogICAgZW1haWwgPSBiZW5zbEBtaWNyb3NvZnQuY29tCgo= | base64 -d > "$HOME/.cache/git-work-config.inc"
            chmod 777 "$HOME/.cache/git-work-config.inc"
        fi
    fi
}

lc_assert_user_is_not root

lc_login () {
    if ! grep -F .m.recolic /etc/hosts > /dev/null; then
        gpg -d -o /tmp/.hosts.tmp files/secrets/work-hosts.asc &&
            sudo mv /tmp/.hosts.tmp /etc/hosts
    fi
}

