function rnfs.mount
    ping -c 1 hms.recolic
    and sudo mount -o bg,intr,hard,timeo=1,retrans=1,actimeo=1,retry=1 hms.recolic:/ /home/recolic/nfs
end
