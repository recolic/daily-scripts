function rgpg-sign-msg
	set fname $argv[1]
gpg --clearsign -a $fname
return $status
end
