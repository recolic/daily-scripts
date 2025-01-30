function rgpg-decrypt
	if [ (count $argv) != 1 ]
echo 'Usage: rgpg-decrypt <filename>.gpg'
return 1
end

set fname $argv[1]
set fucked_fname (echo $fname | sed -E 's/\\.(gpg|asc)$//')
gpg --decrypt -o $fucked_fname $fname
return $status
end
