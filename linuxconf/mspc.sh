# base: fresh-installed archlinux

lc_include arch-common/* utils/arch-virt.sh

lc_assert_user_is root

lc_startup () {
    mount --uuid 6bee9d09-ffb9-4728-89cd-26e0f6aeaa12 /extradisk
    
    # swtpm. For devbox VM
    mkdir -p /extradisk/swtpm/mytpm
    lc_bgrun /tmp/swtpm.log bash -c 'cd /extradisk/swtpm ; while true; do swtpm socket --tpm2 --tpmstate dir=./mytpm --ctrl type=unixio,path=./mytpm.sock; done'

    lc_bgrun /tmp/frpc-cdn.log auto_restart frpc -c files/secrets/mspc-frpc-cdn.ini
    lc_bgrun /tmp/frpc.log     auto_restart frpc -c files/secrets/mspc-frpc.ini
    lc_bgrun /tmp/frps.log     auto_restart frps -c files/secrets/mspc-frps.ini

    lc_bgrun /tmp/cron.log     every 30m bash files/srv-deps/mspc-check-internet.sh
    lc_bgrun /tmp/cron.log     every 1m  bash files/mspc-simple-vmm/cron-callback.sh
    lc_bgrun /tmp/cron.log     every 5m  curl https://recolic.net/api/mspc-keepalive.php
}
