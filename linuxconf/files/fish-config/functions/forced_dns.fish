function forced_dns
	if [ "$argv" = "" ]
echo "Usage: forced_dns <dns server>"
return 1
end
sudo fish -c "echo 'nameserver $argv' > /etc/resolv.conf"
end
