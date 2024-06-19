# vfpctrl completion script v2

# cached list, [ "/get-flow-logging-packet-counter%Gets number of UDP packets sent for flow logging." , ...]
set __vfpctrl_command_and_desc (vfpctrl /help | sed 's/^ *//' | grep '^/' | sed 's/ .*- /%/g')

function __vfpctrl_complete_get_ports
    vfpctrl -list-all-ports | grep Port: | sed 's/^ *Port: //'
end

function __fish_vfpctrl_complete2
    set -l COMP_LINE (commandline -p)
    set -l COMP_POINT (string length (commandline -cp))
    echo "DEBUG: $COMP_LINE / $COMP_POINT" > /tmp/1.log
    # check if line[point-1] is space
    # if is space:
    #   determine if previous word is /port or -port
    #   if true:
    #     complete ports
    #   otherwise:
    #     complete commands
    # else is not space: (in middle of word)
    #   complete commands (both / and -)
   
    # note: fish index starts with 1, not 0
    set -l ar (string split ' ' "$COMP_LINE")
    if test $ar[-1] = ''
        set -l ar_stripped (string split ' ' (string trim "$COMP_LINE"))
        set -l last_word $ar_stripped[-1]
    else
        set -l last_word $ar[-1]
    end

    set -l last_word (string replace / - $last_word)
    if test $last_word = -port
        if test $help_mode = 1
            echo "port"
        else
            __vfpctrl_complete_get_ports
        end
    else
        # completing first arg, dont use keyword
        if $last_word = vfpctrl
            set -l last_word ""
        end

        for line in $command_and_desc
            set ar (string split % "$line")
            set command $ar[1]
            set desc $ar[2]
            if string match "*$last_word*" "$line"
                if test $help_mode = 1
                    echo $desc
                else
                    echo $command
                end
            end
        end
    end
    
end
# complete --command vfpctrl -f -a '(__fish_vfpctrl_complete2)'
complete --command vfpctrl -f -a '(__fish_vfpctrl_complete2)' -r '(help_mode=1 __fish_vfpctrl_complete2)'

#    exit #####
#    
#    complete -c vfpctrl -f
#    
#    # set commands (vfpctrl /help | sed 's/^ *//' | grep -o '^/[a-zA-Z0-9_-]*')
#    # complete -c vfpctrl -a $commands
#    
#    for line in $command_and_desc
#        set ar (string split % "$line")
#        set command $ar[1]
#        set desc $ar[2]
#        # Sometimes help message not correctly formatted..
#        set command (echo "$command" | grep -o '^/[a-zA-Z0-9_-]*' | tr '/' '-')
#    
#        if not test -z $desc
#            set extra_args -d "$desc"
#        end
#    
#        # special command special treatment.
#        if test $command = -port
#            complete -c vfpctrl -o port -a '(__vfpctrl_complete_get_ports)' -f -r $extra_args
#            continue
#        end
#        # for all normal commands
#        complete -c vfpctrl -a $command $extra_args
#    end
#    
#    
