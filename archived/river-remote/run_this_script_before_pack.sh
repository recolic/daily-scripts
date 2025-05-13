#!/bin/bash
[[ "$R_SEC_FRP_KEY" = "" ]] && echo "ERROR: please set secret" && exit 1

sed -i "s/_PLACEHOLDER_FRP_KEY_/$R_SEC_FRP_KEY/" *.ini

rm -fr frp_0.51.3_windows_amd64.zip frp_0.51.3_windows_amd64/

wget https://github.com/fatedier/frp/releases/download/v0.51.3/frp_0.51.3_windows_amd64.zip &&
    unzip frp_0.51.3_windows_amd64.zip &&
    mv frp_0.51.3_windows_amd64/frpc.exe .

rm -fr frp_0.51.3_windows_amd64.zip frp_0.51.3_windows_amd64/
