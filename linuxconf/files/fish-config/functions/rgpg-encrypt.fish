function rgpg-encrypt
	if [ (count $argv) != 1 ]
echo 'Usage: rgpg-encrypt <filename>'
return 1
end

set fname $argv[1]
gpg --encrypt -o $fname.gpg -r root@recolic.net $fname
return $status
end
