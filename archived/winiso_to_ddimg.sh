#!/bin/bash

function do_rufus () {
    qemu-system-x86_64 -drive file=/home/recolic/qemu/workbox-new.qcow2,if=virtio -m 8G -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time -smp 4 -vnc :9 --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -nic tap,ifname=vnic0,script=no,downscript=no,mac=10:11:11:11:11:10 -drive if=none,id=stick,format=raw,file=/home/recolic/qemu/usb.img -device nec-usb-xhci,id=xhci -device usb-storage,bus=xhci.0,drive=stick && 
    mv usb.img "$iso".ddimg_gptuefi 
    return $?
}
function do_windows2usb () {
    sudo losetup -P /dev/loop0 usb.img && 
    sudo windows2usb /dev/loop0 "$iso" mbr && 
    mv usb.img "$iso".ddimg_hybridsplit
    res=$?
    sudo losetup -d /dev/loop0
    return $res
}

iso="$1"
sz_bytes=`stat --printf=%s "$iso"` &&
sz_kib=`echo "1 + $sz_bytes/1024 + 21650 + 20000" | bc` &&
qemu-img create -f raw usb.img "$sz_kib"K && 
# do_rufus
do_windows2usb


exit $?


