#!/bin/bash

# Function to test internet connection
test_internet() {
    ping -c 1 cloudflare.com > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        return 0
    else
        ping -c 1 1.1.1.1 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            return 1
        else
            return 2
        fi
    fi
}

# Function to select a random DNS server
select_random_dns() {
    dns_servers=("10.50.10.50" "1.1.1.1")
    rand_index=$((RANDOM % ${#dns_servers[@]}))
    selected_dns=${dns_servers[$rand_index]}
    echo "nameserver $selected_dns" > /etc/resolv.conf
    # curl 'https://1.1.1.1/dns-query?name=proxy.recolic.net&type=A' -vH "accept: application/dns-json"
}

# Function to fix internet using fix-2
fix_2() {
    dhcpcd br0 &
    sleep 20
}

# Function to fix internet using fix-3
fix_3() {
    pkill dhcpcd
    ip link set eno2 nomaster
    ip link delete br0 type bridge
    ip link set eno2 up
    dhcpcd eno2 &
    sleep 20
}

# Main function
main() {
    # Check if eno2 is up
    ip link show eno2 > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "eno2 is not up. Exiting."
        exit 1
    fi

    # Loop to test internet connection 5 times
    for (( i=1; i<=5; i++ )); do
        test_internet
        case $? in
            0)
                echo "Internet is working. Exiting."
                exit 0
                ;;
            1)
                echo "Internet is available but without DNS."
                select_random_dns
                ;;
            2)
                echo "No internet connection."
                ;;
        esac
        if [ $i -lt 5 ]; then
            sleep 60
        fi
    done

    # If last check is internet without DNS, exit
    if [ $? -eq 1 ]; then
        echo "Internet is still not working with DNS. Exiting."
        exit 1
    fi

    # Try fix-2
    echo "Trying fix-2..."
    fix_2
    test_internet
    if [ $? -eq 0 ]; then
        echo "Internet is working after fix-2. Exiting."
        exit 0
    fi

    ## TOO AGREESIVE DISABLE ## # Try fix-3
    ## TOO AGREESIVE DISABLE ## echo "Trying fix-3..."
    ## TOO AGREESIVE DISABLE ## fix_3
    ## TOO AGREESIVE DISABLE ## test_internet
    ## TOO AGREESIVE DISABLE ## if [ $? -eq 0 ]; then
    ## TOO AGREESIVE DISABLE ##     echo "Internet is working after fix-3. Exiting."
    ## TOO AGREESIVE DISABLE ##     exit 0
    ## TOO AGREESIVE DISABLE ## fi

    echo "Internet is still not working after all fixes. Exiting."
    exit 1
}

# Run the main function
main

