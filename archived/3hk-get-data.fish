

function get_data_used
    curl -s 'https://www.three.com.hk/ft-prepaid-pro/sim/H3SUB0000151833/getSubProfile' --compressed -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0' -H 'Accept: application/json, text/plain, */*' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Pragma: no-cache' -H 'platformId: PREPAID_WEB' -H 'platformVersion: 0.31.0' -H 'Authorization: Basic dXNlcjozLmNvbVVYdWF0' -H 'Connection: keep-alive' -H 'Referer: https://www.three.com.hk/prepaid/DIY/en/account/dashboard' -H 'Cookie: AMCV_4CC40C3A53DB08800A490D4D%40AdobeOrg=-637568504%7CMCIDTS%7C19774%7CMCMID%7C49821900624560283942223234132087289909%7CMCOPTOUT-1708445497s%7CNONE%7CvVersion%7C5.1.1; s_cc=true; d70e6e9a58c89e14460d5b0c18e197b1=ddf2b4185050088b5f8125db7ffd30df; TS011f9f53=01378af9ef9471dcac99c29ab5d73223ba3a0e82a820f151b1c8fcc6bdb0c1d9de1905d1b9543492cbf5d820f907e334838b84e7c7; AMCVS_4CC40C3A53DB08800A490D4D%40AdobeOrg=1; SWSID=ZWMxZDgyNTQtZGIyOS00NGVhLTk5YjktNzdlMDQyMDhkMjY5; TS0180ee58=01378af9ef8f85cf0061be47fd6b9f7e62fbbf72a19812495a37b571339d93548944a59e75230e8ec6fe2de2b2f42736bce6bcb818; THREESID=YTAxNDg1ZmEtODgwZS00ZDRlLWI5ZjgtYzUzOGU1OTE5Zjk1' -H 'Sec-Fetch-Dest: empty' -H 'Sec-Fetch-Mode: cors' -H 'Sec-Fetch-Site: same-origin' -H 'Cache-Control: no-cache' | grep -o 'balanceAmount[^,]*,' | grep -v ':0.0,' | cut -d : -f 2 | tr -d ','
end

set used (get_data_used)

echo "STAT: $used MB / 30720 MB"

