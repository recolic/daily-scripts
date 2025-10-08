function mslab-tunnel
    if test (count $argv) != 0 ; and test $argv[1] = of
        echo "old fashioned tunnel..."
        ssh -L 127.0.0.1:10803:127.0.0.1:30002 -Nn ms.recolic
    else
        echo "tunnel..."
        sshpass -p (rsec MSPASS) ssh -D 10809 -Nn (rsec MSID)@jb3.backup2.m.recolic
    end
end
