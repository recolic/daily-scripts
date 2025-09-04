function mslab-tunnel
    sshpass -p (rsec MSPASS) ssh -D 10809 -Nf (rsec MSID)@jb3.team1.m.recolic
end
# backup
# function mslab-tunnel
#     if test (count $argv) != 0 ; and test $argv[1] = b
#         ssh -L 30627:127.0.0.1:30627 -Nf msbackup.recolic
#     else
#         ssh -L 30627:127.0.0.1:30627 -Nf ms.recolic
#     end
# 
#     string match "*"(rsec LABJUMP_SS_KEY)"*" (ps aux)
#     or begin
#         # only shadowsocks-rust allowed
#         nohup sslocal -s 127.0.0.1:30627 -k (rsec LABJUMP_SS_KEY) -b 127.0.0.1:10809 -m chacha20-ietf-poly1305 >/tmp/.ss.log 2>&1 & disown
#     end
# end
