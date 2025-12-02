# setup this linuxconf on fresh-installed archlinux

lc_include arch-common/* arch-desktop/*

lc_init () {
    lc_todo "
============================================
Next Steps: 
  set password for new user 'recolic';
  reboot, login as recolic;
  enable gnome extensions;
  login Nextcloud;
============================================
"
}
