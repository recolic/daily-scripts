function write51
	sudo sdcc $argv.c;
packihx $argv.ihx > $argv.hex;
sudo ./stcflash.py $argv.hex;
end
