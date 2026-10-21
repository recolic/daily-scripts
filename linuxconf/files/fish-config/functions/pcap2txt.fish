function pcap2txt
    tshark -r $argv[1]  -n -t ud -T tabs -o 'gui.column.format:"No.","%m","Time","%t","Source","%us","Destination","%ud","Protocol","%p","Length","%L","SrcPort","%uS","DstPort","%uD","Desc","%i"'
end
