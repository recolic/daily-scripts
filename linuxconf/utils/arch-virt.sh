# For archlinux virtualization needs, depends on arch-common
lc_assert_user_is root

lc_init () {
    # https://git.recolic.net/root/simple-vm-manager
    pacman -Sy --needed --noconfirm cdrkit qemu-system-x86 qemu-base edk2-ovmf aria2

    pacman -Sy --needed --noconfirm docker
}

