# az vm list-ip-addresses  --resource-group recolic-79c4cc7c-a8f0-4bf8-9add-6ab657c2fddb --output table > /tmp/gg
# # srvs
# cat /tmp/gg | grep -- '-[0-9] ' | sed 's/ 10.*$//' | sed 's/^[^ ]*//' | tr -d ' ' | tr '\n' ' '
# srvs lans 
# cat /tmp/gg | grep -- '-[0-9] ' | grep ' 10.*$' -o | cut -d , -f 1 | tr -d ' '   | tr '\n' ' '
# # clis
# cat /tmp/gg | grep -- '-[0-9][0-9] ' | sed 's/ 10.*$//' | sed 's/^[^ ]*//' | tr -d ' ' | tr '\n' ' '
#
#
# MPC➜  vfp git:(main) cat /tmp/i2 | cut -d , -f 1 | grep . | sed 's/ [^ ]*$//' | tr -d ' ' | tr '\n' ' '
# 20.252.203.10 20.252.205.10 20.252.203.8 20.252.203.107 20.252.201.129 20.252.204.204 20.252.203.141 20.252.203.223 20.252.203.110 20.252.204.171 20.252.203.77 20.252.203.173 20.252.203.252 20.252.204.161 ⏎                         MPC➜  vfp git:(main) cat /tmp/i2 | cut -d , -f 1 | grep . | sed 's/^[^ ]*//' | tr -d ' ' | tr '\n' ' '
# 10.0.0.11 10.0.0.24 10.0.0.17 10.0.0.18 10.0.0.35 10.0.0.10 10.0.0.32 10.0.0.34 10.0.0.27 10.0.0.14 10.0.0.9 10.0.0.29 10.0.0.4 10.0.0.20 ⏎                                                                                            MPC➜  vfp git:(main) cat /tmp/i1 | cut -d , -f 1 | grep . | sed 's/ [^ ]*$//' | tr -d ' ' | tr '\n' ' '
# 20.252.203.232 20.252.203.127 20.252.204.248 20.252.204.127 20.252.204.124 20.252.204.107 20.252.204.34 20.252.205.79 20.252.203.94 20.252.204.187 20.252.203.191 20.252.204.134 20.252.205.42 20.252.204.56 ⏎                         MPC➜  vfp git:(main) cat /tmp/i1 | cut -d , -f 1 | grep . | sed 's/^[^ ]*//' | tr -d ' ' | tr '\n' ' '
# 10.0.0.30 10.0.0.21 10.0.0.12 10.0.0.26 10.0.0.28 10.0.0.23 10.0.0.5 10.0.0.31 10.0.0.22 10.0.0.15 10.0.0.33 10.0.0.25 10.0.0.7 10.0.0.8 ⏎

set clis 20.252.203.10 20.252.205.10 20.252.203.8 20.252.203.107 20.252.201.129 20.252.204.204 20.252.203.141 20.252.203.223 20.252.203.110 20.252.204.171 20.252.203.77 20.252.203.173 20.252.203.252 20.252.204.161
set srvs 20.252.203.232 20.252.203.127 20.252.204.248 20.252.204.127 20.252.204.124 20.252.204.107 20.252.204.34 20.252.205.79 20.252.203.94 20.252.204.187 20.252.203.191 20.252.204.134 20.252.205.42 20.252.204.56
set srvlans 10.0.0.30 10.0.0.21 10.0.0.12 10.0.0.26 10.0.0.28 10.0.0.23 10.0.0.5 10.0.0.31 10.0.0.22 10.0.0.15 10.0.0.33 10.0.0.25 10.0.0.7 10.0.0.8


# setup
for ip in $clis $srvs
    echo ">> SETUP $ip"
    sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 r@$ip bash -c "'echo func=setup > /tmp/1'"
    sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 r@$ip bash -c "'curl https://recolic.cc/tmp/cps-setup.sh >> /tmp/1'"
    sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 r@$ip bash -c "'echo $R_SEC_WEAK12 | sudo -S bash /tmp/1'"  &
end

echo "++ wait for setup jobs..."
wait

# start srv
for ip in $srvs
    echo ">> SRV START $ip"
    set b64 (echo 'curl https://recolic.cc/tmp/cps-setup.sh > /tmp/s ; env func=server bash /tmp/s' | base64 -w0)
    sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 root@$ip bash -c "'echo $b64| base64 -d > /tmp/cmd ; tmux new-session -d  bash /tmp/cmd'" &
end

echo "++ wait for start-srv jobs..."
wait

## start cli
set cter 0
for ip in $clis
    set cter (math 1+$cter)
    set peerip $srvlans[$cter]
    echo ">> CLI START $ip == $peerip"
    # sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 root@$ip bash -c "'curl https://recolic.cc/tmp/cps-setup.sh > /tmp/s ; env ip=$peerip func=client bash /tmp/s'"
    set b64 (echo "curl https://recolic.cc/tmp/cps-setup.sh > /tmp/s ; env ip=$peerip func=client bash /tmp/s" | base64 -w0)
    sshpass -p $R_SEC_WEAK12 ssh -o ServerAliveInterval=3 root@$ip bash -c "'echo $b64| base64 -d > /tmp/cmd ; tmux new-session -d  bash /tmp/cmd'" &
end

echo "++ wait for start cli jobs..."
wait

