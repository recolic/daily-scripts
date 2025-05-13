
function mon
    curl -s 'https://www.visa.go.kr/openPage.do?MENU_ID=10301' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://www.visa.go.kr' -H 'Connection: keep-alive' -H 'Referer: https://www.visa.go.kr/openPage.do?MENU_ID=10301' -H 'Cookie: WMONID=5c5MtqofabU; JSESSIONID_evisa=aaNSQfGXXmD9SaGdIGCMaQpkAyt9oeOniGsoXwHbtm2OO22UxAfFXQStQSlKdTCN.evisawas2_servlet_EVISA' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw 'CMM_TEST_VAL=test&sBUSI_GB=PASS_NO&sBUSI_GBNO=EH7948571&ssBUSI_GBNO=EH7948571&pRADIOSEARCH=gb03&sEK_NM=LIU+BENSONG&sFROMDATE=1998-12-23&sMainPopUpGB=main&TRAN_TYPE=ComSubmit&SE_FLAG_YN=&LANG_TYPE=EN'  | tr -d '\r\n' | grep -o 'PROC_STS_CDNM_1[^-]*-' | grep Application | sed 's/^.*>//g' | grep '[A-Za-z][A-Za-z ]*' -o
end

# Defined in /home/recolic/.config/fish/functions/mailr.fish @ line 2
function mailr
    # Send email to root@recolic.net.
    set -l message $argv[1]
    set -l title "[mailr] RECOLIC SHELL NOTIFY"

    echo ">>> Sending email:" root@recolic.net "$title: $message" 1>&2
    curl "https://recolic.net/api/email-notify.php?apiKey=$R_SEC_MAILAPI_KEY&recvaddr=root@recolic.net&b64Title="(echo $title | base64)'&b64Content='(echo "[mailr] $message" | base64 -w 0) 1>&2
    return $status
end

if test "$R_SEC_MAILAPI_KEY" = ""
    echo ERROR need SECRET
    exit 1
end

while true
    date
    set stat (mon)
    if test $stat != 'Application Received'
        echo ALERT "$stat"
        mailr "KR VISA stat: $stat"
    end
    sleep 10m
end

