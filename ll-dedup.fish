for line in (grep V: $argv[1] | cut -d : -f 2 | uniq)
    echo $line | base64 -d | gzip -d
    echo ...................
end

