# Defined in - @ line 2
function warn --description 'alias warn=cvlc --play-and-exit /home/recolic/sh/running-config/warn.ogg'
	pactl set-sink-volume 0 200%
    cvlc --play-and-exit /home/recolic/sh/running-config/warn.ogg $argv
end
