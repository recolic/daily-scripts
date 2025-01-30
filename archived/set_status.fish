#!/bin/fish

function _usage
        echo "
        This script will edit /home/www/mirrors/.status autoly.
        If the attribute doesn't exist, I'll create it.
        Or I'll edit it.
        I'll set its time to correct value automatically.

        Usage: ./this.fish <attr name> <status>
        'status' is usually one of these value: Succeed, Failed, Syncing, and so on...
        "
        exit 2
end

set _arg_len (count $argv)
if [ $_arg_len != '2' ]
        _usage
end

set name $argv[1]
set _status $argv[2]
set time (date +%m-%d_%H:%M:%S) 

set _path 'dat' #'/home/www/mirrors/.status'

cat $_path | grep -v "^$name " > $_path.tmp
echo "$name $time $_status" >> $_path.tmp
cat $_path.tmp | sort > $_path
rm $_path.tmp


