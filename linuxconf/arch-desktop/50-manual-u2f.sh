lc_assert_user_is root

lc_init () {
    pacman -Sy --needed --noconfirm pam-u2f
    echo "Manual Steps: pamu2fcfg -urecolic > /etc/u2f_mappings"
    echo "Manual Steps: INSERT 'auth sufficient pam_u2f.so authfile=/etc/u2f_mappings cue pinverification=1' INTO /etc/pam.d/gdm-password"
}

