function lshiftEnable --description alias\ lshiftEnable=xmodmap\ -e\ \'keycode\ 50\ =\ Shift_L\'
	xmodmap -e 'keycode 50 = Shift_L' $argv;
end
