lc_assert_user_is_not root

lc_init () {
    # from old init.bash
    # re-entry: yes

echo "## Basic package config (kernel-param, pacman, pkg install, gpg, fcitx, service, ...)"

echo "========= GPG config"
# Warning: pinentry-curses bug: ERR 83918950 Inappropriate ioctl for device
gpg --keyserver keyserver.ubuntu.com --recv-keys E3933636 &&
echo "pinentry-timeout 0
pinentry-program /usr/bin/pinentry-gnome3
enable-ssh-support" > "$HOME/.gnupg/gpg-agent.conf" &&
echo "CDF90134A15862BB1568F01DFC450A62DFB5376F 0" > "$HOME/.gnupg/sshcontrol" || die 

echo "##WARNING## To make effect in current session, you might need run 'set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)' in fish"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpg-connect-agent reloadagent /bye
## For non-GUI setup: 
#set -g GPG_TTY (tty)
#gpg-connect-agent updatestartuptty /bye

# TODO: this only works inside gnome
echo "========= gnome desktop config"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type nothing
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type nothing
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.interface enable-hot-corners false
gsettings set org.gnome.desktop.media-handling automount false
gsettings set org.gnome.desktop.media-handling automount-open false
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "['<Shift><Alt>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "['<Shift><Alt>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "['<Shift><Alt>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "['<Shift><Alt>Down']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Super><Shift>Left']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "['<Super><Shift>Up']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "['<Super><Shift>Down']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Primary>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Primary><Shift>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab', '<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab', '<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.interface clock-format '24h'
# gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot-clip "['disabled']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot-clip "['<Primary>Print']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys window-screenshot "['disabled']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot-clip "['<Primary><Shift>Print']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys area-screenshot "['Print']"
# gsettings set org.gnome.settings-daemon.plugins.media-keys screenshot "['<Shift>Print']"

lc_fsmap "files/vimrc" "$HOME/.vimrc"
lc_fsmap "files/vim" "$HOME/.vim"
lc_fsmap "files/gitconfig" "$HOME/.gitconfig"
lc_fsmap "files/ssh_config" "$HOME/.ssh/config"
lc_fsmap "files/i3_config" "$HOME/.i3/config"
lc_fsmap "files/gnome-extensions" "$HOME/.local/share/gnome-shell/extensions"
lc_fsmap "files/fish-config" "$HOME/.config/fish"
}


