# base: fresh-installed archlinux

lc_include arch-common/* utils/arch-virt.sh

lc_assert_user_is root

lc_startup () {
    mount --uuid 6bee9d09-ffb9-4728-89cd-26e0f6aeaa12 /extradisk
    
    # swtpm. For devbox VM
    mkdir -p /extradisk/swtpm/mytpm
    lc_bgrun /tmp/swtpm.log bash -c 'cd /extradisk/swtpm ; while true; do swtpm socket --tpm2 --tpmstate dir=./mytpm --ctrl type=unixio,path=./mytpm.sock; done'

    # For emergency access only
    lc_bgrun /tmp/frpc.log  auto_restart bash -c "curl -s https://recolic.net/api/ms-rpctl.php | grep rp.enabled=1 && frpc -c files/secrets/mspc-frpc.ini ; sleep 10m"

    lc_bgrun /tmp/cron.log  every 30m bash utils/mspc-check-internet.sh
    lc_bgrun /tmp/cron.log  every 1m  bash files/mspc-simple-vmm/cron-callback.sh
    lc_bgrun /tmp/cron.log  every 5m  curl https://recolic.net/api/mspc-keepalive.php
}
