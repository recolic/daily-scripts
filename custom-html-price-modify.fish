#!/bin/fish
# modify all price in HTML to 70%, to fuck the chinese import custom.
function modify
    set fname $argv[1]
    set RATE 0.7 # 1.2
    # with leading $
    set prices (cat $fname | grep '\\$[0-9-]*\\.[0-9][0-9]' -o | tr -d '$' | sort | uniq)
    # without leading $, 1-3 digit
    # cat $fname | grep '\\[0-9-][0-9]?[0-9]?\\.[0-9][0-9]' -o | sort | uniq

    cp $fname /tmp/reduced.tmp
    for price in $prices
        set reduced (python -c "print('%.2f' % ($price*$RATE))")
        # with leading $
        set price "\$$price"
        set reduced "\$$reduced"

        echo "TO REPLACE $price -> $reduced"
        python -c "print(open('/tmp/reduced.tmp').read().replace('$price', '$reduced'))" > /tmp/reduced.tmp.1
        mv /tmp/reduced.tmp.1 /tmp/reduced.tmp
    end
    mv /tmp/reduced.tmp $fname-reduced.html
    echo "DONE. output file: $fname-reduced.html"
end

modify $argv[1]




