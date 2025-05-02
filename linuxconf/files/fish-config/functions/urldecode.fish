# Defined in - @ line 1
function urldecode --wraps='python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"' --description 'alias urldecode=python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))"'
  python3 -c "import sys, urllib.parse as ul; print(ul.unquote_plus(sys.argv[1]))" $argv;
end
