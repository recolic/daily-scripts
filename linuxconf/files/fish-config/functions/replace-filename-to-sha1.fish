function replace-filename-to-sha1
for fl in $argv
set hash (cat $fl | sha1sum | cut -d ' ' -f 1)
set hash (string sub -s 1 -e 12 $hash)
mv $fl $hash(path extension $fl)
end
end
