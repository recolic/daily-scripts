# Defined in /tmp/fish.LLHfc2/aws_push.fish @ line 2
function aws_push
	p aws s3 cp $argv[1] "s3://recolic-backend.xyz/$argv[2]" --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
end
