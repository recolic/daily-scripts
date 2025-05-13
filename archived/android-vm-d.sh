#!/bin/bash

# qemu-system-x86_64 -vnc :6 -enable-kvm -m 4096 -smp 4 -cpu host -drive file=android.qcow2,if=virtio
 # -cdrom ~/nfs/rpc_downloads/systems/android-x86_64-9.0-r2.iso -boot d
  qemu-system-x86_64 \
  -vnc :6 \
  -enable-kvm \
  -M q35 \
  -m 4096 -smp 4 -cpu host \
  -bios /usr/share/ovmf/x64/OVMF.fd \
  -drive file=android.qcow2,if=virtio \
  -usb \
  -device virtio-tablet \
  -device virtio-keyboard \
  -device qemu-xhci,id=xhci \
  -machine vmport=off \
  -net nic,model=virtio-net-pci -net user,hostfwd=tcp::4444-:5555
  

exit
###############

_self_bin_name="$0"
function where_is_him () {
    SOURCE="$1"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo -n "$DIR"
}

function where_am_i () {
    _my_path=`type -p ${_self_bin_name}`
    [[ "$_my_path" = "" ]] && where_is_him "$_self_bin_name" || where_is_him "$_my_path"
}

cd "$(where_am_i)"

while true; do
  qemu-system-x86_64 \
  -vnc :6 \
  -enable-kvm \
  -M q35 \
  -m 4096 -smp 4 -cpu host \
  -bios /usr/share/ovmf/x64/OVMF.fd \
  -drive file=android.qcow2,if=virtio \
  -usb \
  -device virtio-tablet \
  -device virtio-keyboard \
  -device qemu-xhci,id=xhci \
  -machine vmport=off \
  -net nic,model=virtio-net-pci # -net user,hostfwd=tcp::4444-:5555
  
  echo "Using 0.0.0.0:5906 VNC"
  sleep 5
done

exit




