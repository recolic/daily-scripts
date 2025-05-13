function mkrand () {
echo $(($RANDOM$RANDOM % 10000))
}
###############
echo Creating session...
reply=`curl 'https://pxlme.me/yVqVUzxe' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' -vv -L 2>&1 | grep -E 'Set-Cookie: PHP|Location: ./'`
cookie=`echo "$reply" | grep Set-Cookie | grep -o 'PHPSESSID=[0-9a-f]*;' | tail -n1`
session_path_hash=`echo "$reply" | grep -o './[0-9a-f]*/' | grep -o '[0-9a-f]*'`
echo session created: "$session_path_hash + $cookie"

function curlw () {
    echo "DEBUG: CURLW $@"
    curl "$@" -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' --cookie "$cookie" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -w "%{http_code}\n"
}

curlw "https://clientmail11.duckdns.org/$session_path_hash/submission@login" --data-raw "email=youfucked$RANDOM%40gmail.com&submit=Submit+Query"
curlw "https://clientmail11.duckdns.org/$session_path_hash/submission@continue" --data-raw "password=YouFucked$RANDOM&submit=Submit+Query&rememberMe=true"
curlw "https://clientmail11.duckdns.org/$session_path_hash/submission@billing" --data-raw "country=US&fullname=Your+Fucking+name&phone=11122$(mkrand)&address=$RANDOM+Your+Mom+Asshole&address2=Apt+Duck&city=San+Francisco&state=CA&zipcode=91111&dob=11%2F11%2F1988&ssn=102-10-2211&submit=Submit+Query"
curlw "https://clientmail11.duckdns.org/$session_path_hash/submission@card" --data-raw "noc=Resp+Jeck&cn=51133200249$(mkrand)&acid=&cem=04&cey=2028&3d=193"

exit

curl "https://clientmail11.duckdns.org/$session_path_hash/submission@login" -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://clientmail11.duckdns.org' -H 'Connection: keep-alive' -H 'Referer: https://clientmail11.duckdns.org/$session_path_hash/70573a969c6ca836be8c0f2c422278ef.aspx' -H "$cookie: PHPSESSID=462cd660a91219c497779270b6076a6c' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw "email=youfucked$RANDOM%40gmail.com&submit=Submit+Query"

curl "https://clientmail11.duckdns.org/$session_path_hash/submission@continue" -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://clientmail11.duckdns.org' -H 'Connection: keep-alive' -H 'Referer: https://clientmail11.duckdns.org/$session_path_hash/70573a969c6ca836be8c0f2c422278ef.aspx' -H "$cookie: PHPSESSID=462cd660a91219c497779270b6076a6c' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw 'password=YouFucked$RANDOM&submit=Submit+Query&rememberMe=true'


curl "https://clientmail11.duckdns.org/$session_path_hash/submission@billing" -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://clientmail11.duckdns.org' -H 'Connection: keep-alive' -H 'Referer: https://clientmail11.duckdns.org/$session_path_hash/70573a969c6ca836be8c0f2c422278ef.aspx' -H "$cookie: PHPSESSID=462cd660a91219c497779270b6076a6c' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw 'country=US&fullname=Your+Fucking+name&phone=11122'$(mkrand)'&address=$RANDOM+Your+Mom+Asshole&address2=Apt+Duck&city=San+Francisco&state=CA&zipcode=91111&dob=11%2F11%2F1988&ssn=102-10-2211&submit=Submit+Query'

curl "https://clientmail11.duckdns.org/$session_path_hash/submission@card" -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:104.0) Gecko/20100101 Firefox/104.0' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Content-Type: application/x-www-form-urlencoded' -H 'Origin: https://clientmail11.duckdns.org' -H 'Connection: keep-alive' -H 'Referer: https://clientmail11.duckdns.org/$session_path_hash/70573a969c6ca836be8c0f2c422278ef.aspx' -H "$cookie: PHPSESSID=462cd660a91219c497779270b6076a6c' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: same-origin' -H 'Sec-Fetch-User: ?1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw 'noc=Resp+Jeck&cn=51133200249'$(mkrand)'&acid=&cem=04&cey=2028&3d=193'


