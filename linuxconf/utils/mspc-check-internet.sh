#!/bin/bash

# Function to test internet connection
test_internet() {
    for (( i=1; i<=5; i++ )); do
        ping -c 1 cloudflare.com > /dev/null 2>&1
        [ $? -eq 0 ] && return 0 # GOOD
        sleep 5
    done

    for (( i=1; i<=5; i++ )); do
        ping -c 1 1.1.1.1 > /dev/null 2>&1
        [ $? -eq 0 ] && return 1 # NO_DNS
        sleep 5
    done

    return 2 # BAD
}
IF_MAIN=eno2
IF_BACKUP=wlo1

select_fb_dns1() {
    echo "nameserver 10.50.10.50" > /etc/resolv.conf
    # curl 'https://1.1.1.1/dns-query?name=proxy.recolic.net&type=A' -vH "accept: application/dns-json"
}

fix_2() {
    # dhcpcd br0 &
    dhcpcd $IF_MAIN &
    sleep 20
}


fix_switch_line() {
    echo "nameserver 1.1.1.1" > /etc/resolv.conf

    backup_if_route=`ip r | grep '^default' | grep "dev wlo1"`
    metric_min=`ip r | grep '^default' | grep 'metric [0-9]*' -o | cut -d ' ' -f 2 | sort -h | head -n1`

    return 1
    ip route add $backup_if_route
    # TODO
    
}

main() {
    test_internet
    case $? in
        0)
            echo "Internet is working. Run remote command if any."
            curl -s https://recolic.net/api/mspc-emergency-cmd.php > /tmp/.emergency-cmd && bash /tmp/.emergency-cmd
            exit 0
            ;;
        1)
            echo "Internet is available but without DNS."
            select_fb_dns1
            ;;
        2)
            echo "No internet connection."
            ;;
    esac
    test_internet && exit
    [ $? = 1 ] && exit # wont help

    echo "Trying fix-2..."
    fix_2
    test_internet && exit

    # echo "TRY fix_switch_line"
    # fix_switch_line
    # test_internet && exit

    echo "Internet is still not working after all fixes. Exiting."
    exit 1
}

main

