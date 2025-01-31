#!/bin/bash
# This script deploys n test VMs into a vnet, and optionally, you can make it deploy into TiP session.

COLOR_BLU='\033[0;34m'
COLOR_CLR='\033[0m'
function var_default_val () { eval "[ -z \$$1 ]" && export "$1=$2" ;echo -ne "$COLOR_BLU"; eval "echo \"  >> $1 = \$$1\"" ;echo -ne "$COLOR_CLR"; }

location="$1"
vmcount="$2"
tipid="$3"
cluster="$4"

# D/E_v5 for OVL, D/E_v4 for non-ovl. Refer to Azure doc for more details.
var_default_val vmsize              Standard_E2_v5
var_default_val vnet_ipv6           0
var_default_val vnet_enc            0
var_default_val accelnet            1

# If set to n: First n VMs will be deployed into TiP (if provided TiP session), and TiP session would be ignored for the rest VMs.
var_default_val only_n_vms_in_tip   999

# Use alternative IP range. Set a non-zero number (1-253) if you need vnet peering. Will be part of LAN addr.
var_default_val vnet_altaddr        0

var_default_val prefix              $(short=1 today || echo zz)$(head -c6 /dev/urandom | base64 -w0 | tr -d =/+)
var_default_val resgrp              rshgrp-$prefix
var_default_val vmname              $prefix-vm
var_default_val avname              $vmname-av
var_default_val vnetname            $vmname-vnet

# At 202405, the following image are allowed for internal use: ["2022-datacenter-azure-edition","2022-datacenter","2022-datacenter-core","2022-datacenter-azure-edition-core","2022-datacenter-core-g2","2022-datacenter-g2","pro-22_04","pro-22_04-gen2","24_04","24_04-gen2","22_04-lts-arm64","azure-linux-3","azure-linux-arm64","azure-linux-gen2","1-gen2","cbl-mariner-1","cbl-mariner-2","cbl-mariner-2-arm64","cbl-mariner-2-fips","cbl-mariner-2-gen2","cbl-mariner-2-gen2-fips","cbl-mariner-2-kata","79-gen2"]
# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
# az vm image list --publisher Canonical --output table --all | grep 0001-com-ubuntu-pro-microsoft | grep 22_04-gen2
[[ "$vmsize" == *v3 ]] && var_default_val vmimg Canonical:0001-com-ubuntu-pro-microsoft:pro-22_04:22.04.202405240 # not supporting gen2
var_default_val vmimg               Canonical:0001-com-ubuntu-pro-microsoft:pro-22_04-gen2:22.04.202405240

# Path to an executable (usually bash script) to upload & run on VM creation. Don't forget your shebang!
var_default_val vmsetup_exec

var_default_val plugin_src          https://git.recolic.net/root/daily-scripts/-/raw/one/srv-deps/azv-plugin-
var_default_val plugin
var_default_val dryrun              0

######## Configuration END #########################################

[ "$plugin" = "" ] || curl "$plugin_src$plugin" -o /tmp/.azv-plugin-$plugin || ! echo "Failed to load plugin $plugin" || exit 1
[ -f "/tmp/.azv-plugin-$plugin" ] && source "/tmp/.azv-plugin-$plugin"
function call_if_any () { [ "$(LC_ALL=C type -t $1)" = function ] && $1 ; }

if [ "$vmcount" = "" ]; then
    echo "
azvm-deploy.sh v2501.1
This script deploys n test VMs into a vnet, and optionally, you can make it deploy into TiP session.
Usage: $0 <location> <vmcount> [tipid] [cluster]
Example: $0 eastus2euap 2
         $0 eastus2euap 2 69b25fda-d568-4460-b515-0c77ef6719ce CBN09PrdApp09

Optionally, you can override some variables by setting corresponding env. For example:
         resgrp=mygrp vmsize=Standard_D2_v3 $0 eastus2euap 2 ...
Optional variables (read script for help):
$(grep '^var' $0 | sed 's/^/  /')

Known bug: if deploying too many VMs into single TiP session, this script might fail. Try traditional deploy.ps1
"
    call_if_any plugin_help
    exit 1
fi

vm_create_xtra_arg=()
vm_create_xtra_arg_first_n=()
vnet_create_xtra_arg=()

[ "$vnet_enc"       = 1 ] && vnet_create_xtra_arg+=(--enable-encryption true --encryption-enforcement-policy allowUnencrypted)
[ "$vnet_ipv6"      = 1 ] && vnet_create_xtra_arg+=(--address-prefixes 10.0.0.0/16 fd00:db8:deca::/48 --subnet-prefixes 10.0.0.0/24 fd00:db8:deca::/64)
[ "$accelnet"       = 1 ] && vm_create_xtra_arg+=(--accelerated-networking true)
[ "$vmsetup_exec" != "" ] && vm_create_xtra_arg+=(--user-data "$vmsetup_exec")
vm_admin_pass=$(rsec WEAK12) || vm_admin_pass=dummypassW12

## all args ready to go!

COLOR_RED_BLD='\033[1;31m'
function debugexec () {
    echo -e "$COLOR_BLU.. EXEC #" "$@" "$COLOR_CLR" 1>&2
    [ "$dryrun" != 0 ] || "$@" ; return $?
}

echo -e "${COLOR_RED_BLD}II Deploy $vmcount VMs at location $location, in res_grp $resgrp ...$COLOR_CLR"

# Create RG if not exists.
if ! az group show -g "$resgrp" > /dev/null 2>&1; then
    debugexec az group create -n "$resgrp" --location "$location"
fi

# Create an availability set if we want deploy into TiP.
if [ "$tipid" != "" ]; then
    echo -e "${COLOR_RED_BLD}++ Using TiP session $tipid at cluster $cluster$COLOR_CLR"

    # `az vm availability-set create` doesn't allow setting internalData.pinnedFabricCluster, we must use the ugly ARM deployment.
    echo "H4sIAAAAAAAAA31TTY/aMBC98yssb6VtJUgC7WX3VrFaqYfthd1eVqgakgGmdWzLnoAo4r/XTgJs+EoixZr3Zvzma9sT4ZGffL7EEuSjkEtm6x/TtLEkJWhYYImaE/hXOUxyU7aYT0fZ8GGQfRtkw7RAq8wm8l6xtAoYkz/e6DvZb27IjeYA/kLnyeh40TDJ4rsnWHBQIgc8gNvaVtthpYM92ITYSt7YeJQTdqQXctc/8pTJgZvQN3lMloo63G1eriof1ETmOa+mtWy5AkcwU3gi/HeoVKxH9IsFmRtXvtkiVObJlEB6bCrNAnQh9ugzVIo7oENR4DyaBRsxFKTFmnRh1l743JHlRGjDwofGiPUS2AteoigRdJCZiDcffqLu2z6O7Eh36E3l8lr6+0H6MYmmYm3yL5Q7482ck7EpbcWYwgpIwYwU8WaC7GW/6wmWPjR8lI2+DrLwDU95bYfl+3EIPt83jb//Mj1lf+h012MPXPBhWHTbc0Beyf40BSYT9FHoj+IsbD0xMWbHeXdyg/9bXb5gn9x3RQuNxe0o1hmLjgmvqL02KvVCnSTdcTibvKseFBbVaVBPwHBRRBOXdEjmGWaO8vFhVbqFa1forHQXEq9jrshxBeoF8iXpZian3Wr1uqdpb9f7D7e+f03CBAAA" | base64 -d | gzip -d > /tmp/template-avset.json
    debugexec az deployment group create -g "$resgrp" --template-file /tmp/template-avset.json --parameters "avname=$avname" "location=$location" "tipid=$tipid" "cluster=$cluster" || exit $?
    vm_create_xtra_arg_first_n+=(--availability-set "$avname")
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

call_if_any plugin_before_vm_creat

for cter in $(seq $vmcount); do
    debugexec az vm create -g "$resgrp" --name "$vmname$cter" --image "$vmimg" --admin-password "$vm_admin_pass" --admin-username r --location "$location" --size "$vmsize" --vnet-name "$vnetname" --subnet default "${vm_create_xtra_arg[@]}" "${vm_create_xtra_arg_first_n[@]}" || exit $?

    if [ "$vnet_ipv6" = 1 ]; then
        debugexec az network nic ip-config create -g "$resgrp" --name "$vmname${cter}-xtraipc" --nic-name "$vmname${cter}VMNic" --private-ip-address-version IPv6 --vnet-name "$vnetname" --subnet default
    fi

    # Clear these args for only 1st VM
    [ "$cter" -ge "$only_n_vms_in_tip" ] && vm_create_xtra_arg_first_n=()
    [ "$cter" -ge "$only_n_vms_in_tip" ] && vmsize=Standard_E4_v4
done

call_if_any plugin_after_vm_creat
