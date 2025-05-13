function rgpg-encrypt-msg
	if [ (count $argv) = 0 ]
gpg --yes --encrypt -a -r root@recolic.net
else
if [ (count $argv) != 1 ]
echo 'Usage: rgpg-encrypt-msg [filename]'
return 1
end
set fname $argv[1]
gpg --yes --encrypt -a -o $fname.asc -r root@recolic.net $fname
end
return $status
end
