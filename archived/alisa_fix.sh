#!/bin/bash
# Mar 14, 2018, by Recolic Keghart <root@recolic.net>
# Fix mixed http/https content for Alisahhh.github.io
# Required by alisad.sh

git_dir=$1
[[ $git_dir == '' ]] && echo 'Usage: ./alisa_fix.sh <web_root>' && exit 1

function process_a_file () {
    fname=$1
    tmpfl=`mktemp`
    # http to https
    cat $fname | sed 's/http:\/\/cube-1252774894.cosgz.myqcloud.com/https:\/\/cube-1252774894.cosgz.myqcloud.com/g' |
        sed 's/http:\/\/blog.qzwlecr.com/https:\/\/blog.qzwlecr.com/g' |
        sed 's/http:\/\/ww4.sinaimg.cn/https:\/\/ww4.sinaimg.cn/g' |
        sed 's/http:\/\/scarletthuang.cn/https:\/\/scarletthuang.cn/g' |
        sed 's/http:\/\/www.w3.org/https:\/\/www.w3.org/g' |
        sed 's/http:\/\/aplayer.js.org/https:\/\/aplayer.js.org/g' |
        sed 's/cube-1252774894.cosgz.myqcloud.com\/music\/lrc\/Dear friends - TRIPLANE.lrc/alisa.asia\/res\/Dear_friends_TRIPLANE.lrc/g' |
        sed 's/cube-1252774894.cosgz.myqcloud.com\/music\/lrc\/Butter-Fly (ピアノヴァージョン) - 和田光司.lrc/alisa.asia\/res\/ButterFly.lrc/g' |
        sed 's/cube-1252774894.cosgz.myqcloud.com\/music\/lrc\/宵闇花火 - 葉月ゆら.lrc/alisa.asia\/res\/x.lrc/g' > $tmpfl
    chmod +r $tmpfl
    mv $tmpfl $fname
}

[[ ! -d $git_dir ]] && echo 'Error: web_root not exists' && exit 2

for fl in $(grep 'http://' -r $git_dir | grep ':' | cut -d ':' -f 1 | uniq)
do
    echo "Checking $fl..."
    process_a_file $fl
done

[[ ! -L $git_dir/res ]] && ln -s /var/www/html/res $git_dir/res && chmod +rx $git_dir/res

