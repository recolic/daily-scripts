#!/bin/fish
# fish-bash-init.fish. Use bash or python-venv env script for fish.
# Auto-detect:
#   ./scripts/init-dev-env.sh
#   ./venv/bin/activate.fish

set workdir .
set sh_candidates ./scripts/init-dev-env.sh ./venv/bin/activate ./bin/activate
for f in $sh_candidates
    test -e $f; and set script $f
end
if test -z $script
    echo "$sh_candidates doesn't exist"
    exit 1
end
echo "Loading bash env $script for fish..."

if test (count $argv) != 0
    # All operations except init don't have any side effect. Simply forward it. 
    set real_script_path $script_dir/init-dev-env.sh
    bash $real_script_path $argv
    exit $status
else
    # Init operation has side effects. Carefully eval & launch a new shell.

    # We must do the init within a specific CWD. Warning: The path MUST NOT contain single-quote character. 
    set tmp_fname (mktemp)

    bash -c "cd '$workdir' && source $script && env > $tmp_fname"
        or exit $status

    # Got the environment variable file. Let's set all variables except SHLVL, _, and PWD. 
    set variables_to_set (cat $tmp_fname | grep -vE '^(SHLVL|_|PWD)=')
    for variable_pair in $variables_to_set
        set sep_pos (string split ' ' (string match --regex --index = $variable_pair))[1]
        set var_name (string sub --start 1 --length (math $sep_pos-1) $variable_pair)
        set var_val (string sub --start (math $sep_pos+1) $variable_pair)
        set -gx $var_name $var_val
    end

    rm -f $tmp_fname
    echo "Environment initialized. Enjoy."
    env RECOLIC_ENV_NAME=ARM64 fish
    exit $status
end
