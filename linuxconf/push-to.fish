# sync linuxconf to recolic server, and populate secret.
#
# I'm publishing my linuxconf dir as example, so it cannot contain any secret.
# You don't need to do the same. Just put secret as-is.

if not test -f push-to.fish
    echo "ERROR: please run this script in its directory"
    exit 1
end

#echo "ERROR: DO NOT test this script before back to US"
#exit 1

function e
    echo $argv
    eval $argv
    or exit 1
end

if test $argv[1] = mspc
    e rsync -avz --progress --delete . ms.recolic:lc.desktop
    e rsync -avz --progress --delete /home/recolic/.git-credentials ms.recolic:/home/recolic/.git-credentials
    # The whole file should be secret
    for fl in secrets/mspc-*.gpg
        # rsec_populate ms.recolic lc.desktop/$fl
        rgpg-decrypt-remote ms.recolic lc.desktop/$fl
    end
else if test $argv[1] = hms
    e rsync -avz --progress --delete . hms.r:lc.desktop
    set used_sec (grep "rsec [^)]*" -o hms.sh | cut -d ' ' -f 2)
    rsec_export $used_sec | ssh hms.r "cat > /etc/RSEC_alt"
else
    echo Usage: push-to.fish mspc/hms
end

