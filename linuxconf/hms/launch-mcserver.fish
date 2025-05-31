#!/usr/bin/fish

## For mc1.12
archlinux-java set java-8-openjdk/jre
## For mc1.18
# archlinux-java set java-17-openjdk

cd /mnt/fsdisk/mcserver-1.12-tf-jwl-akkocloud-20191207-x
# cd /mnt/fsdisk/technode-tfc-server-1.12
# cd /mnt/fsdisk/mcserver-tfc118
and tmux new-session -s mcserver-tmux -d "sh linux-start.sh ; fish"

# only use this for 1.12-tf-jwl world 
if pwd | grep mcserver-1.12-tf-jwl
    while true
        tmux send-keys -t mcserver-tmux.0 "improvedMobs difficulty set 20" ENTER
        sleep 20m
    end
end

### not using mc-backup-d, because zfs daily backup is enough
# nohup /mnt/fsdisk/mcserver-1.12-tf-jwl-akkocloud-20191207-x/mcserver-backup-daemon.fish & disown
# nohup /mnt/fsdisk/technode-tfc-server-1.12/mcserver-backup-daemon.fish & disown

