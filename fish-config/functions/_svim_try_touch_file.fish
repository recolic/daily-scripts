function _svim_try_touch_file
	#return 1 indicates permission denied, 0 indicates success, 2 indicates unknown error.
touch $argv[1] > /dev/null 2>&1
if test $status -ne 0
return 1
else
rm -f $argv[1]; and return 0; or return 2
end
end
