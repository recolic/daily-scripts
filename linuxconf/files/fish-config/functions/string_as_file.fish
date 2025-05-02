function string_as_file
set s (mktemp --suffix=fish-string-to-file-tmp)
echo "$argv[1]" > $s
echo $s
end
