#!/usr/bin/fish
# Verify gpg-clearsign generated file with multi-gpg_signed_message_block.
# Usage: ./this.fish toverify.asc
#        cat toverify.asc | ./this.fish

function _do_verify
    set buffl (mktemp)
    set counter 0

    while read -P '' _line
        echo "$_line" >> $buffl
        if string match -r -- '-----END PGP SIGNATURE-----' "$_line" > /dev/null
            echo "Verifying block $counter:"
            gpg --verify $buffl
            rm $buffl
            set counter (math "$counter+1")
        end
    end

    rm $buffl
end

if test (count $argv[1]) -eq 1
    cat $argv[1] | _do_verify
else
    _do_verify
end

