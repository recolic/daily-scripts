# About this script

## usage

server setup:

1. Use `push_update_to_server.sh` to upload current directory.
2. add cronjob: `0 18 * * * /storage/storage-server-backup-sh/daily.fish >> /var/log/recolic-backup.log 2>&1`
3. generate ssh host key, also generate ssh key pair
4. add sshkey to every server, set this ssh config, try ssh manually

```
Host *
    ServerAliveInterval 240 
    StrictHostKeyChecking no

Host remote.nfs.recolic
    Hostname base.ddns1.recolic.net
    Port 25567
    User root

Host func.drive.recolic
    Hostname git.recolic.net
    Port 4022
    User root

Host func.main.recolic
    Hostname func.main.recolic.net
    Port 22
    User root
```

# About storage server

## setup or migration

```
# Copy the following things to new machine:
/root/.ssh
/storage
crontab -l
# [optional] /etc/ssh (and restart sshd afterward)

# If fish version < 3.0, install latest fish 3.x:
apt install software-properties-common
apt-add-repository ppa:fish-shell/release-3
apt update ; apt upgrade ; apt install fish

gpg --recv-keys --keyserver hkps://keyserver.ubuntu.com C344D5EAE3933636
```

# setup extern backup

https://git.recolic.net/root/storage.recolic.net-extern

