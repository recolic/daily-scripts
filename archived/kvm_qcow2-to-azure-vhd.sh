#!/usr/bin/bash


qcow2="$1"
vhddisk="$qcow2.vhd"
rawdisk="$qcow2.raw"

qemu-img convert -f qcow2 -O raw "$qcow2" "$rawdisk" || exit 1

MB=$((1024*1024))
size=$(qemu-img info -f raw --output json "$rawdisk" | \
       gawk 'match($0, /"virtual-size": ([0-9]+),/, val) {print val[1]}')

rounded_size=$((($size/$MB + 1)*$MB))
echo "Rounded Size = $rounded_size"


qemu-img resize "$rawdisk" $rounded_size &&
qemu-img convert -f raw -o subformat=fixed,force_size -O vpc "$rawdisk" "$vhddisk" &&
rm "$rawdisk"

