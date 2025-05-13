# Defined in - @ line 1
function urlencode --wraps='python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))"' --description 'alias urlencode=python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))"'
  python3 -c "import sys, urllib.parse as ul; print (ul.quote_plus(sys.argv[1]))" $argv;
end
