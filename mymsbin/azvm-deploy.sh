#!/bin/bash
# This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.

location="$1"
vmcount="$2"
tipid="$3"
cluster="$4"

vmsize="${vmsize:=Standard_E2_v5}"
vnet_ipv6=0
vnet_enc=1
accelnet=1

# Use alternative IP range. Set a non-zero number (1-253) if you need vnet peering. Will be part of LAN addr.
vnet_altaddr=0

prefix="${prefix:=$(head -c8 /dev/urandom | base64 -w0 | tr -d =/+)}"
resgrp="${resgrp:=rshgrp-$prefix}"
vmname="${vmname:=$prefix-vm}"
avname="$vmname-av"
vnetname="${vnetname:=$vmname-vnet}"

# At 202405, the following image are allowed for internal use: ["2022-datacenter-azure-edition","2022-datacenter","2022-datacenter-core","2022-datacenter-azure-edition-core","2022-datacenter-core-g2","2022-datacenter-g2","pro-22_04","pro-22_04-gen2","24_04","24_04-gen2","22_04-lts-arm64","azure-linux-3","azure-linux-arm64","azure-linux-gen2","1-gen2","cbl-mariner-1","cbl-mariner-2","cbl-mariner-2-arm64","cbl-mariner-2-fips","cbl-mariner-2-gen2","cbl-mariner-2-gen2-fips","cbl-mariner-2-kata","79-gen2"]
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
# az vm image list --publisher Canonical --output table --all | grep 0001-com-ubuntu-pro-microsoft | grep 22_04-gen2
vmimg=Canonical:0001-com-ubuntu-pro-microsoft:pro-22_04-gen2:22.04.202405240

######## Check usage... Script user: Do not modify below this line. #########################################
[ "$vmcount" = "" ] && echo "This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.
Usage: $0 <location> <vmcount> [tipid] [cluster]
Example: $0 eastus2euap 2
         $0 eastus2euap 2 69b25fda-d568-4460-b515-0c77ef6719ce CBN09PrdApp09

Optionally, you can override other variables by setting corresponding env. For example:
         resgrp=mygrp vmsize=Standard_D2_v3 $0 eastus2euap 2 ...

Known bug: if deploying too many VMs, this script might fail to deploy all of them. Try traditional deploy.ps1
" && exit 1

vm_create_xtra_arg=()
vnet_create_xtra_arg=()

[ "$vnet_enc"     = 1 ] && vnet_create_xtra_arg+=(--enable-encryption true --encryption-enforcement-policy allowUnencrypted)
[ "$vnet_ipv6"    = 1 ] && vnet_create_xtra_arg+=(--address-prefixes 10.0.0.0/16 fd00:db8:deca::/48 --subnet-prefixes 10.0.0.0/24 fd00:db8:deca::/64)
[ "$accelnet"     = 1 ] && vm_create_xtra_arg+=(--accelerated-networking true)
[ "$R_SEC_WEAK12" = "" ] && R_SEC_WEAK12=dummypassW12

## all args ready to go!

function debugexec () {
    echo ".. EXEC #" "$@" 1>&2
    "$@" ; return $?
}

echo "II Deploying $vmcount $vmsize VMs at location $location, using res_grp $resgrp, vmname $vmname, with accelnet=$accelnet, vnet_enc=$vnet_enc, vnet_ipv6=$vnet_ipv6, vnet_altaddr=$vnet_altaddr ..."

# Create RG if not exists.
if ! az group show -g "$resgrp" > /dev/null 2>&1; then
    debugexec az group create -n "$resgrp" --location "$location" > /dev/null 2>&1
fi

# Create an availability set if we want deploy into TiP.
if [ "$tipid" != "" ]; then
    echo "++ Using TiP session $tipid at cluster $cluster"

    # `az vm availability-set create` doesn't allow setting internalData.pinnedFabricCluster, we must use the ugly ARM deployment.
    echo "H4sIAAAAAAAAA31TTY/aMBC98yssb6VtJUgC7WX3VrFaqYfthd1eVqgakgGmdWzLnoAo4r/XTgJs+EoixZr3Zvzma9sT4ZGffL7EEuSjkEtm6x/TtLEkJWhYYImaE/hXOUxyU7aYT0fZ8GGQfRtkw7RAq8wm8l6xtAoYkz/e6DvZb27IjeYA/kLnyeh40TDJ4rsnWHBQIgc8gNvaVtthpYM92ITYSt7YeJQTdqQXctc/8pTJgZvQN3lMloo63G1eriof1ETmOa+mtWy5AkcwU3gi/HeoVKxH9IsFmRtXvtkiVObJlEB6bCrNAnQh9ugzVIo7oENR4DyaBRsxFKTFmnRh1l743JHlRGjDwofGiPUS2AteoigRdJCZiDcffqLu2z6O7Eh36E3l8lr6+0H6MYmmYm3yL5Q7482ck7EpbcWYwgpIwYwU8WaC7GW/6wmWPjR8lI2+DrLwDU95bYfl+3EIPt83jb//Mj1lf+h012MPXPBhWHTbc0Beyf40BSYT9FHoj+IsbD0xMWbHeXdyg/9bXb5gn9x3RQuNxe0o1hmLjgmvqL02KvVCnSTdcTibvKseFBbVaVBPwHBRRBOXdEjmGWaO8vFhVbqFa1forHQXEq9jrshxBeoF8iXpZian3Wr1uqdpb9f7D7e+f03CBAAA" | base64 -d | gzip -d > /tmp/template-avset.json
    debugexec az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster" || exit $?
    vm_create_xtra_arg+=(--availability-set "$avname")
fi

if [ "$vnet_altaddr" != 0 ]; then
    vnet_iprange=10.$vnet_altaddr.0.0
    echo "++ alt_addr: vnet IP range $vnet_iprange"
    vm_create_xtra_arg+=(--vnet-address-prefix $vnet_iprange/16 --subnet-address-prefix $vnet_iprange/24)
    vnet_create_xtra_arg+=(--address-prefixes $vnet_iprange/16 --subnet-prefixes $vnet_iprange/24)
fi

if [ "$vnet_enc" = 1 ] || [ "$vnet_ipv6" = 1 ]; then
    # These advanced vnet options are not available from az-vm-create
    if ! az network vnet show -g "$resgrp" --name "$vnetname" > /dev/null 2>&1; then
        debugexec az network vnet create -g "${resgrp}" --location "${location}" --name "${vnetname}" --subnet-name default "${vnet_create_xtra_arg[@]}" || exit $?
    fi
fi

for cter in $(seq $vmcount); do
    debugexec az vm create -g "$resgrp" --name "$vmname$cter" --image "$vmimg" --admin-password $R_SEC_WEAK12 --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}" || exit $?

    if [ "$vnet_ipv6" = 1 ]; then
        debugexec az network nic ip-config create -g "$resgrp" --name "$vmname${cter}-xtraipc" --nic-name "$vmname${cter}VMNic" --private-ip-address-version IPv6 --vnet-name "$vnetname" --subnet default
    fi
done

