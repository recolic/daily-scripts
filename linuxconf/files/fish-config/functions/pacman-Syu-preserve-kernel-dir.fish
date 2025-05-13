function pacman-Syu-preserve-kernel-dir
rm -rf /tmp/upgrade-kernel-dir-backup
cp -r /usr/lib/modules/(uname -r) /tmp/upgrade-kernel-dir-backup
and sudo pacman -Syu
and begin
test -d /usr/lib/modules/(uname -r)
or sudo mv /tmp/upgrade-kernel-dir-backup /usr/lib/modules/(uname -r)
end
end
