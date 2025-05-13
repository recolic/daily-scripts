#!/bin/fish
# Script to make backup to rsync-server
# Usage: ./this [nocfg]
set DST 'recolic@drive.recolic.net:share'
function setdir 
	echo "Backuping object $argv"
	rsync -Lvaz --progress $argv $DST
end

#initssh-check
#if test "$status" -ne 1
#	echo 'Error: ssh-agent not inited. Try initssh first. '
#	exit 69
#end

date -Iseconds > ln-to-backup/last-update
setdir ln-to-backup

if test "$argv" = "noconfig" 
    echo 'Non-config backup done. Exiting...'
	exit 0
end

# if with config:
ps -aux | grep 'google/chrome/chrome' | grep -v grep > /dev/null 2>&1
if test "$status" -ne 1
    echo 'Error: DO NOT run google-chrome while making full backup.'
    exit 70
end

ps -aux | grep 'visual-studio-code' | grep -v grep > /dev/null 2>&1
if test "$status" -ne 1
    echo 'Error: DO NOT run vscode while making full backup.'
    exit 70
end

echo 'Mv large cache file out...'
mv ~/.config/Code ~/tmp/._back_Code_con
mv ~/.config/google-chrome/Default ~/tmp/._back_chrome_con
setdir .config
echo 'Recover large cache... [Warning: DO NOT interupt!]'
mv ~/tmp/._back_chrome_con ~/.config/google-chrome/Default
mv ~/tmp/._back_Code_con ~/.config/Code
echo 'Done.'

# skip encrypted_data folder.
exit 0
