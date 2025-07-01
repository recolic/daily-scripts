function rnfs.mount
    ping -c 1 hms.r
    and sudo mount -o bg,intr,hard,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
end
