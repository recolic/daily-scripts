function rnfs.mount
sudo mount -o bg,intr,soft,timeo=1,retrans=1,actimeo=1,retry=1 hms.r:/ /home/recolic/nfs
end
