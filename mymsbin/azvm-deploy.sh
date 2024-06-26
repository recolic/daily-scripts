#!/bin/bash
# This script deploys n VMs into the same vnet, and optionally, you can make it deploy into TiP session.

location="$1"
vmcount="$2"
tipid="$3"
cluster="$4"

vmsize="${vmsize:=Standard_D2_v5}"
vnet_ipv6=0
vnet_enc=0
accelnet=1

# Use alternative IP range. Turn this on if you need vnet peering.
vnet_altaddr=1

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
    echo "EXEC #" "$@" 1>&2
    "$@" ; return $?
}

echo "Deploying $vmcount $vmsize VMs at location $location, using res_grp $resgrp, vmname $vmname, with accelnet=$accelnet, vnet_enc=$vnet_enc, vnet_ipv6=$vnet_ipv6 ..."
az group create -n "$resgrp" --location "$location" > /dev/null 2>&1

# Create an availability set if we want deploy into TiP.
if [ "$tipid" != "" ]; then
    echo "++ Using TiP session $tipid at cluster $cluster"

    # `az vm availability-set create` doesn't allow setting internalData.pinnedFabricCluster, we must use the ugly ARM deployment.
    echo "H4sIAAAAAAAAA31TTY/aMBC98ysst9K2EoTAtofurWK1Ug/bC7u9rFA1JAOZ1rEtewKiiP9eOwmw4SuJFGvem5k3H972RHjkR58VWIJ8ELJgtv5hOGwsSQkallii5gT+VQ6TzJQt5ofjdPRtkH4ZpKNhjlaZTeS9YGkVMCZ/vNEfZL/JkBnNAfyFzpPRMdEoSeO7J1hwUCIHPIDb2lbbYaWDPdiE2Ere2HiUU3akl3LXP/KUyYCb0Dd5TJbyOtxtXqYqH9RE5jmvprVsuQJHMFd4Ivx36FTsR/SLDVkYV77aPHTm0ZRAemIqzQJ0LvboE1SKO6BDkeMimgUbMRKkxZp0btZe+MyR5URow8KHwYh1AewFFyhKBB1kJuLVh5+o57aPIzvSHXpTuayW/naQfiyi6Vhb/DNlzniz4GRiSlsxDmEFpGBOingzRfay3/UES+8GPk7H94M0fKNTXjth+XZcgk93zeDvPs9O2e8m3fXYAxd8GJbd8RyQF7I/TY7JFH0U+iM/C1tvTIzZcd6dZPB/q8sJ9sV9V7TUmN+OYp2x6JjwitqrixToX/vX+aerFejjC3QKl9RpUI/AcFFAE5R0KOQJ5o6yyeGadJvWXp+ztl0ouo65IscVqGfICtLNPs66nep1T7Pervcf6ISSqr4EAAA=" | base64 -d | gzip -d > /tmp/template-avset.json
    debugexec az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster" || exit $?
    vm_create_xtra_arg+=(--availability-set "$avname")
fi

if [ "$vnet_altaddr" = 1 ]; then
    vm_create_xtra_arg+=(--vnet-address-prefix 10.1.0.0/16 --subnet-address-prefix 10.1.0.0/24)
fi

if [ "$vnet_enc" = 1 ] || [ "$vnet_ipv6" = 1 ]; then
    [ "$vnet_altaddr" = 1 ] && "!! WARNING! vnet_enc/vnet_ipv6 option cannot work together with vnet_altaddr. vnet_altaddr=1 ignored. If you do need this feature, plz modify the script. It's easy."
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

