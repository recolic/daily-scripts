# Defined in - @ line 0
function p --description 'proxychains with port 10809 / 10829'
    if test (count $argv) != 0 ; and test $argv[1] = h
        echo "PORT 10829" >&2
        proxychains-with-port.sh 10829 $argv[2..]
    else if test (count $argv) != 0 ; and test $argv[1] = 8
        echo "PORT 10808" >&2
        proxychains-with-port.sh 10808 $argv[2..]
    else if test (count $argv) != 0 ; and test $argv[1] = 9
        echo "PORT 10809" >&2
        proxychains-with-port.sh 10809 $argv[2..]
    else
        echo "PORT 1080" >&2
        proxychains-with-port.sh 1080 $argv[1..]
    end

    # proxychains -q $argv;
end
