function hzip
    if test (count $argv) -lt 1
        echo Usage: hzip dir_name
        return 1
    end
    if not test -d $argv[1]
        echo Usage: hzip dir_name. Error: argument is not a dir
        return 1
    end
    set zip_fname (basename $argv[1]).zip
    echo "Creating zip_file $zip_fname from "$argv[1]
    zip -e -P (genpasswd $zip_fname) -r $zip_fname $argv[1]
end

function hmount
    if test (count $argv) -lt 1
        echo Usage: hmount zip_fname
        return 1
    end
    if not test -f $argv[1]
        echo Usage: hmount zip_fname. Error: argument is not a file
        return 1
    end
    set zip_fname $argv[1]
    set zip_dir (mktemp -d)
    echo "Mount $zip_fname to $zip_dir"
    genpasswd "$zip_fname" | mount-zip $zip_fname $zip_dir
    or return $status

    fish --private -C "cd $zip_dir"
    umount $zip_dir
end

