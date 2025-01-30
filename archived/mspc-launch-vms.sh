#!/bin/bash

# nohup qemu-system-x86_64 workbox-win.qcow2 -m 10G -cpu host -smp 8 -vnc :9 --enable-kvm -nic tap,ifname=vnic0,script=no,downscript=no,mac=10:11:11:11:11:10 -usb -device usb-host,hostbus=1,hostaddr=17  & disown
# nohup qemu-system-x86_64 workbox-win.qcow2 -m 10G -cpu host -smp 8 -vnc :9 --enable-kvm -nic tap,ifname=vnic0,script=no,downscript=no,mac=10:11:11:11:11:10 -usb -device usb-host,vendorid=0x08e6,productid=0x3437 & disown

# exit # disabled RECOLICVWIN, it does not compliant anymore. 
nohup bash -c 'cd /extradisk/qemu ; while true; do swtpm socket --tpmstate dir=./mytpm --ctrl type=unixio,path=./mytpm.sock; done' & disown
cd /extradisk/qemu
nohup qemu-system-x86_64 -drive file=/extradisk/qemu/devbox2023.qcow2,if=virtio -m 8G -cpu host,hv_relaxed,hv_spinlocks=0x1fff,hv_vapic,hv_time -smp 6 -vnc :9 --enable-kvm -bios /usr/share/edk2-ovmf/x64/OVMF.fd -nic tap,ifname=vnic0,script=no,downscript=no,mac=10:11:11:11:11:10 -chardev socket,id=chrtpm,path=mytpm.sock -tpmdev emulator,id=tpm0,chardev=chrtpm -device tpm-tis,tpmdev=tpm0 & disown
# -tpmdev passthrough,id=tpm0,path=/dev/tpm0 -device tpm-tis,tpmdev=tpm0
# disabled. use git.recolic.net
#nohup qemu-system-x86_64 git-server-box.qcow2 -m 1G -cpu host -smp 1 -vnc :8 --enable-kvm -nic tap,ifname=vnic1,script=no,downscript=no,mac=10:11:11:11:11:18 & disown

