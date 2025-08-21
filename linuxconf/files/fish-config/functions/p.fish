# Defined in - @ line 0
function p --description 'proxychains shorthand with port 1080x'
    if test (count $argv) != 0 ; and test $argv[1] = h
        echo "PORT 10829" >&2
        proxychains-with-port.sh 10829 $argv[2..]
    else if test (count $argv) != 0; and string match -qr '^[0-9]$' -- $argv[1]
        set port 1080$argv[1]
        echo "PORT $port" >&2
        proxychains-with-port.sh $port $argv[2..]
    else
        echo "PORT 1080" >&2
        proxychains-with-port.sh 1080 $argv[1..]
    end
end
