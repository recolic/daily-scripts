function fish_prompt --description 'Write out the prompt'
    set -l color_cwd
    set -l suffix

    set -l emoji (random choice '>_<' '`~`' 'bmb' 'QwQ' 'UwU' 'x_x' '<.<')
    set -l emoji_color (random choice blue brblue brcyan brgreen brmagenta brred brwhite bryellow green cyan magenta red yellow white)

    echo -n -s (set_color purple) (date +'%H:%M') (set_color blue) @ (set_color purple) "$USER" ' ' (set_color FF0) (prompt_pwd) (set_color $emoji_color) " $emoji " (set_color normal) " "
end

