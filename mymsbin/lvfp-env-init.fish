#!/bin/fish
# This script does similar thing with init-dev-env.sh. 
# The only difference is that, init-dev-env.sh works for bash, this script works for fish. 

# If the PR is not getting merged, allow putting this script outside git repo. 
if test "$SCRIPT_DIR" = ""
    set script_dir (dirname (status --current-filename))
    if not test -f "$script_dir/init-dev-env.sh"
        # The directory where_am_i seems invalid. Let's do more guess.
        if test -f "./scripts/init-dev-env.sh"
            set script_dir "./scripts"
        end
    end
    echo "Using guessed script_dir=$script_dir"
else
    set script_dir "$SCRIPT_DIR"
    echo "Using environment variable script_dir=$script_dir"
end


if test (count $argv) != 0
    # All operations except init don't have any side effect. Simply forward it. 
    set real_script_path $script_dir/init-dev-env.sh
    bash $real_script_path $argv
    exit $status
else
    # Init operation has side effects. Carefully evaluate it. 

    # We must do the init within a specific CWD. Warning: The path MUST NOT contain single-quote character. 
    set simulated_workdir "$script_dir/.."
    set tmp_fname (mktemp)

    bash -c "cd '$simulated_workdir' && source scripts/init-dev-env.sh && env > $tmp_fname"
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
