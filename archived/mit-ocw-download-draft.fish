# archive.org is preventing you from download
set curl_options -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) snap Chromium/80.0.3987.132 Chrome/80.0.3987.132 Safari/537.36' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8' -H 'Accept-Language: en-US,en;q=0.5' -H 'Accept-Encoding: gzip, deflate, br' -H 'Connection: keep-alive' -H 'Upgrade-Insecure-Requests: 1' -H 'Sec-Fetch-Dest: document' -H 'Sec-Fetch-Mode: navigate' -H 'Sec-Fetch-Site: none' -H 'Sec-Fetch-User: ?1' -H 'TE: trailers' -k

set lines (curl https://ocw.mit.edu/courses/physics/8-04-quantum-physics-i-spring-2016/video-lectures/part-2/ | grep itunes)

for line in $lines
    set mp4link (echo "$line" | grep -o "https://archive.org/download/[^']*mp4")
    set srtlink (echo "$line" | grep -o "/courses/physics/[^']*srt" | head -1)
    set srtlink "https://ocw.mit.edu$srtlink"
    set fname (basename $mp4link)
    # echo "DEBUG: $mp4link | $srtlink | fn=" (basename $mp4link)
    if not test -f $fname
        curl $curl_options -L -o $fname $mp4link
            or echo "FAIL $status $fname"
    end
    if not test -f $fname.srt
        aria2c $srtlink -o $fname.srt
            or echo "FAIL $status $fname.srt"
    end
end

