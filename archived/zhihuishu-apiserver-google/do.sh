#!/bin/bash
# https://serpapi.com/dashboard

q="$1"
echo "`date`| DEBUG Q=$q" >> log

function show_result_and_exit () {
    result="$1"
    grep -F "RESULT|$(echo "$q"|base64 -w0)|" ./database > /dev/null || 
        echo "RESULT|$(echo "$q"|base64 -w0)|$(echo "$result"|base64 -w0)" >> ./database
    echo "$result"
    exit 0
}

rawurlencode() {
    python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))" "$@"
}
enq=`rawurlencode "$q"`
enq="${enq^^}"
echo "`date`| DEBUG ENQ=$enq" >> log
# This is a naive free-trial api key. To use it reliably, please register your own account.
apikey=fe73710d92604ff71a4aa1f9dde041a3eef8f404e8199b06a1d35ebdb30b07ae

############################# check cache (database)
cacheres=`grep -F "RESULT|$(echo "$q"|base64 -w0)|" ./database | head -n 1 | sed 's/^.*|//g' | base64 -d`
[[ $cacheres != "" ]] && show_result_and_exit "$cacheres"

############################# brute force match
firsttry=`curl --get https://serpapi.com/search -d q="$enq+%E7%AD%94%E6%A1%88" -d location="China" -d hl="en" -d gl="us" -d google_domain="google.com" -d api_key=fe73710d92604ff71a4aa1f9dde041a3eef8f404e8199b06a1d35ebdb30b07ae | grep '答案：' | sed 's/^.*答案：//g' | grep '↓↓本门' | sed 's/↓↓本门.*$//g' | head -n 1`
[[ $firsttry != "" ]] && show_result_and_exit "$firsttry"

# How do I perform google? 
# look this: 
# 
# +--------------------------------------------------------------------------------------------------+
# |                                                                                                  |
# +--------------------------------------------------------------------------------------------------+
# | VAL: 波兰的国歌是：（）-2021年知到《走进波兰》答案- 艾利格题库          |
# | VAL: 波兰的国歌是：（）-2021年智慧树《走进波兰》答案- 同济搜题          |
# | VAL: 波兰的国歌是：（）-2021年知到《走进波兰》答案-知到仓储管理 ...    |
# | VAL: 波兰的国歌是：（）-2021年知到《走进波兰》答案- 天佑搜题网          |
# | VAL: 波兰的国歌是：（）-2021年智慧树《走进波兰》答案- 承易题库          |
# | VAL: 波兰的国歌是：（）-2021年知到《走进波兰》答案- 淡冰题库             |
# | VAL: 波兰的国歌是：（）-2021年知到《走进波兰》答案-知到四川近代史 ... |
# | VAL: 希望(国歌) - 维基百科，自由的百科全书                                       |
# | VAL: 波兰国歌名字叫什么- 义勇军进行曲 - 小硒知识网                           |
# +--------------------------------------------------------------------------------------------------+
# these website uses the same format to post answers. Let's pull html and parse

############################### brute force match x2
tmpfl=`mktemp`
echo "DEBUG: apires=$tmpfl" 1>&2
#echo curl --get https://serpapi.com/search -d q="$enq+%E7%AD%94%E6%A1%88" -d location="China" -d hl="en" -d gl="us" -d google_domain="google.com" -d api_key=fe73710d92604ff71a4aa1f9dde041a3eef8f404e8199b06a1d35ebdb30b07ae
curl --get https://serpapi.com/search -d q="$enq+%E7%AD%94%E6%A1%88" -d location="China" -d hl="en" -d gl="us" -d google_domain="google.com" -d api_key=fe73710d92604ff71a4aa1f9dde041a3eef8f404e8199b06a1d35ebdb30b07ae > $tmpfl
cat "$tmpfl" | /usr/mybin/json2table /organic_results/link -p | sed 's/VAL: //g' | sed 's/|//g' > "$tmpfl.2"
while IFS= read -r line; do
    thistry=`timeout 1s curl "$line" | grep '<p style="color:red">' | grep '答案：' | sed 's/^.*答案：//g' | sed 's/<.p>.*$//g' | head -n 1`
    [[ $thistry != "" ]] && show_result_and_exit "$thistry"
done < "$tmpfl.2"

