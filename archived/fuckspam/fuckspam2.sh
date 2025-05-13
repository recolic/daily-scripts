
function gen_rand () {
    s=`head -c 128 /dev/urandom | base64 -w0`
    len=$(($RANDOM % 18))
    echo ${s::$len}
}

function reg () {
    curl -s 'http://a.oj3399.cn/index/Index/index.html' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/116.0' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: http://a.oj3399.cn' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: http://a.oj3399.cn/' -H 'Cookie: PHPSESSID=09478b65ba338b72cad8fe924dba6077' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw "name=$(gen_rand)%40$(gen_rand).com&pass=$(gen_rand)&yzcode=5775"
    # echo curl -s 'http://a.oj3399.cn/index/Index/index.html' -X POST -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/116.0' -H 'Accept: application/json, text/javascript, */*; q=0.01' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate' -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' -H 'X-Requested-With: XMLHttpRequest' -H 'Origin: http://a.oj3399.cn' -H 'DNT: 1' -H 'Connection: keep-alive' -H 'Referer: http://a.oj3399.cn/' -H 'Cookie: PHPSESSID=09478b65ba338b72cad8fe924dba6077' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' --data-raw "name=$(gen_rand)%40$(gen_rand).com&pass=$(gen_rand)&yzcode=5775"
}

reg

