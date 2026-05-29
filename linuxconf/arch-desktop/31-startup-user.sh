lc_assert_user_is_not root

NEXTCLOUD_PREFIX="$HOME/"$(ls $HOME | grep -i '^nextcloud$' | head -n1)

lc_startup () {
# firefox config
firefox_config='
user_pref("browser.tabs.tabmanager.enabled", false);
user_pref("services.sync.prefs.sync.browser.uiCustomization.state", true);
user_pref("browser.fixup.domainsuffixwhitelist.recolic", true);
user_pref("browser.tabs.hoverPreview.enabled", false);
user_pref("browser.urlbar.trimURLs", false);'
for dir in "$HOME"/.mozilla/firefox/*.default*; do
  [[ -d "$dir" ]] && echo "$firefox_config" > "$dir/user.js"
done
    
    lc_fsmap "$NEXTCLOUD_PREFIX/documents" "$HOME/Documents"
    lc_fsmap "$NEXTCLOUD_PREFIX/pictures" "$HOME/Pictures"
    
    xdg-user-dirs-update --set DOCUMENTS "$HOME/Documents"
    xdg-user-dirs-update --set PICTURES "$HOME/Pictures"

  local rnote="$HOME/.local/share/applications/note.desktop"
  if [[ -d "$NEXTCLOUD_PREFIX" && "$NEXTCLOUD_PREFIX" != "$HOME/" ]]; then
    if [[ ! -f "$rnote" ]]; then
      mkdir -p "$HOME/.local/share/applications"
      echo "
[Desktop Entry]
Type=Application
Version=1.0
Name=note
Comment=Open my notes folder in Kate
Exec=kate '$NEXTCLOUD_PREFIX'
Icon=accessories-text-editor
Terminal=false
Categories=Utility;TextEditor;
Keywords=note;notes;notebook;rnote;
" > "$rnote"
      chmod +x "$rnote"
    fi
  fi
}

lc_login () {
    if [[ $(hostname) = RECOLICPC ]] || [[ $(hostname) = RECOLICMPC ]]; then
        echo _:1 | bash utils/unlock_keyrings
        # nohup fcitx5 &
    fi
    lc_bgrun /dev/null fish utils/tg-backend-autokill.fish
    lc_bgrun /dev/null python files/mybin/lib/GetIdleTime-daemon.py

    # need smartcard interaction
    # [[ $(hostname) = RECOLICMPC ]] && lc_bgrun /dev/null env IMPL=sshfs bash utils/auto-nfs-mgr.sh
}
