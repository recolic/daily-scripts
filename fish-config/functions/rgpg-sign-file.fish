function rgpg-sign-file
	if [ (count $argv) != 1 ]
echo 'Usage: rgpg-sign-file <filename>'
return 1
end

set fname $argv[1]
gpg --sign --detach-sign $fname
return $status
end
