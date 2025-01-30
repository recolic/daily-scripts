function lshiftDisable --description alias\ lshiftDisable=xmodmap\ -e\ \'keycode\ 50\ =\ 0x0000\'
	xmodmap -e 'keycode 50 = 0x0000' $argv;
end
