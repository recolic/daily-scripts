function smapid
ps aux | grep smagent | grep '[0-9]*' -o | head -n1
end
