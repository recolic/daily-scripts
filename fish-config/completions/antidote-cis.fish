#!/usr/bin/env fish

function cached_function
    # Used in fish_prompt. For huge git repo, executing `git` on every fish_prompt is slow.
    # We can used `cached_function git ...` for faster prompt.
    #
    # Warning: command quotes will be evaluated before entering this func!
    #          `cat 'hello world man.txt'` will not work! use `cat "'hello world man.txt'"`.
    mkdir -p /tmp/.recolic-fish
    set cksum (echo "$argv"(pwd) | cksum | sed 's/ .*$//g')
    set cached_file "/tmp/.recolic-fish/cached_function.$cksum"

    # Warning: race condition: "[[ ! -f $cached_file.ongoing ]] && touch $cached_file.ongoing" is not atomic.
    echo "DEBUG: " nohup bash -c "[[ ! -f $cached_file.ongoing ]] && touch $cached_file.ongoing && $argv > $cached_file.ongoing && mv $cached_file.ongoing $cached_file" > /tmp/dbg.log
    nohup bash -c "[[ ! -f $cached_file.ongoing ]] && touch $cached_file.ongoing && ( $argv > $cached_file.ongoing ; mv $cached_file.ongoing $cached_file )" > /dev/null 2>&1 & disown

    while not test -f $cached_file
        sleep 0.1
    end

    cat $cached_file
end


# Avoid running bearer-gen to make the initialization faster. 
mkdir -p /tmp/.antidote-complete-tmpdir ; and echo '#!/bin/bash' > /tmp/.antidote-complete-tmpdir/bearer-gen ; and chmod +x /tmp/.antidote-complete-tmpdir/bearer-gen
set -l commands_and_desc (env PATH="/tmp/.antidote-complete-tmpdir:$PATH" antidote-cis 2>&1 | grep "The '.*' subcommand" | sed "s/^[^']*'//g" | sed "s/' subcommand /|/g")

set -l __hostname (hostname)
set -l commands
set -l desc
for entry in $commands_and_desc
    set -a commands (echo $entry | sed 's/|.*$//g')
    set -a desc (echo $entry | sed 's/^.*|//g')
end

function __antidote_complete_list_workflows
    set -l candidates (cached_function antidote-cis jobtype-download | grep '<WorkflowDefinition ' | grep -o 'Name="[^"]*"' | grep -o '"[^"]*"' | tr -d '"')
    string collect $candidates
    test (count $candidates) -lt 3 ; and echo -e '<Workflow Name Here>\nSampleWorkflow'
end
function __antidote_complete_list_ver
    set -l wfname (commandline -p | string replace -r -a ' +[^ ]*$' '' | string match -r ' [^ ]*$' | string replace ' ' '')
    set -l candidates (cached_function antidote-cis listver $wfname | cut -d '|' -f 2)
    string collect $candidates
    test (count $candidates) -lt 3 ; and echo -e '<Version Number Here>\n1.0.1'
end
function __antidote_complete_list_jobid
    echo -e '<JOB_ID HERE>\n2517645620722579999_df3a452e-d580-47c2-b96e-61f1671358c9'
end
function __antidote_complete_list_wfargs
    set -l confpath (dirname (type antidote-cis | string replace 'antidote-cis is ' ''))/antidote.config.sh
    set -l candidates (awk '/cis_default_workflow_parameter=/ { output = 1 }; /^ *)/ { output = 0 }; output { print }' $confpath | tail -n +2 | sed 's/^[[:space:]]*//' | grep -o '^[^#].*=')
    string collect $candidates
    test (count $candidates) -lt 3 ; and echo -e 'ParameterName1=Value1\n@RuntimeSettings2=Value2'
end

function __antidote_count_cmdline_args
    # This function counts arguments from a command line text. 
    # It take care of quotes and escaped space. 
    #
    # Note that, "antidote-cis push " counts as 3, because empty argument also counts! This is especially useful for completion. 
    set -l cleaned_cmdline (commandline -p | string replace --regex -a '\\\\.' '' | string replace --regex -a '"[^"]*"' '' | string replace --regex -a "'[^']*'" '' | string replace --regex -a ' +' ' ')
    count (echo $cleaned_cmdline | string split ' ')
end


complete -c antidote-cis --no-file
for i in (seq (count $commands))
    complete -c antidote-cis -n "not __fish_seen_subcommand_from $commands" -a $commands[$i] -d $desc[$i]
end

complete -c antidote-cis -n "__fish_seen_subcommand_from push; and test (__antidote_count_cmdline_args) = 3" --force-files -a "cis:// //$__hostname/"
complete -c antidote-cis -n "__fish_seen_subcommand_from push; and test (__antidote_count_cmdline_args) = 4" -a "(__antidote_complete_list_workflows)"
complete -c antidote-cis -n "__fish_seen_subcommand_from push; and test (__antidote_count_cmdline_args) = 5" -a "(__antidote_complete_list_ver)"

complete -c antidote-cis -n "__fish_seen_subcommand_from release setdef cloudrun listver; and test (__antidote_count_cmdline_args) = 3" -a "(__antidote_complete_list_workflows)"
complete -c antidote-cis -n "__fish_seen_subcommand_from release setdef cloudrun; and test (__antidote_count_cmdline_args) = 4" -a "(__antidote_complete_list_ver)"
complete -c antidote-cis -n "__fish_seen_subcommand_from cloudrun; and test (__antidote_count_cmdline_args) -gt 4" -a "(__antidote_complete_list_wfargs)"

complete -c antidote-cis -n "__fish_seen_subcommand_from jobtype-upload; and test (__antidote_count_cmdline_args) = 3" --force-files

complete -c antidote-cis -n "__fish_seen_subcommand_from jobstatus; and test (__antidote_count_cmdline_args) = 3" -a "(__antidote_complete_list_jobid)"


