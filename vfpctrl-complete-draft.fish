# vfpctrl completion script v2

# cached list, [ "/get-flow-logging-packet-counter%Gets number of UDP packets sent for flow logging." , ...]
set __vfpctrl_command_and_desc (vfpctrl /help | sed 's/^ *//' | grep '^/' | sed 's/ .*- / /' | sed 's/ /%/')
# set __vfpctrl_command_and_desc (cat ~/tmp/vfpctrl-dict-sample.log)

function __vfpctrl_complete_get_ports
    vfpctrl -list-all-ports 2>/dev/null | grep Port: | sed 's/^ *Port: //'
end

function __fish_vfpctrl_complete2
    set -l COMP_LINE (commandline -p)
    set -l COMP_POINT (string length (commandline -cp))
    # check if line[point-1] is space
    # check and set last_word correctly
    # determine if previous word is /port or -port
    # if true:
    #   complete ports
    # otherwise:
    #   complete commands (both starting with / and -)
   
    # note: fish index starts with 1, not 0
    set -l ar (string split ' ' "$COMP_LINE")
    if test $ar[-1] = ''
        set -l ar_stripped (string split ' ' (string trim "$COMP_LINE"))
        set last_word $ar_stripped[-1]
    else
        set last_word $ar[-1]
    end

    # echo "DEBUG: $COMP_LINE / $COMP_POINT" >> /tmp/1.log
    # echo "DEBUG: last_word=$last_word" >> /tmp/1.log
    if test $last_word = -port ; or test $last_word = /port
        if test "$help_mode" = 1
            echo "VFP port"
        else
            __vfpctrl_complete_get_ports
        end
    else
        # completing first arg, dont use keyword
        if test $last_word = vfpctrl
            set last_word ""
        end

        for line in $__vfpctrl_command_and_desc
            set ar (string split % "$line")
            set command $ar[1]
            set command_alt (string replace / - $command)
            set desc $ar[2]
            # Only print matched commands. It's also okay to print all commands, because fish will filter them for us. But in this way we have more control.
            if string match -- "*$last_word*" "$command" > /dev/null
                if test "$help_mode" = 1
                    echo $desc
                else
                    echo $command
                end
                continue # avoid matching command_alt
            end
            if string match -- "*$last_word*" "$command_alt" > /dev/null
                if test "$help_mode" = 1
                    echo $desc
                else
                    echo $command
                end
            end
        end
    end
end
complete --command vfpctrl -f -a '(__fish_vfpctrl_complete2)'
# complete --command vfpctrl -f -a '(__fish_vfpctrl_complete2)' -r '(help_mode=1 __fish_vfpctrl_complete2)'

