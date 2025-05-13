#!/bin/fish

function newwp
    set x $argv[1]
    set y $argv[2]
    set z $argv[3]
    echo '{
  "id": "tmp_TODO=X,TODO=Y,TODO=Z",
  "name": "tmp",
  "icon": "waypoint-normal.png",
  "x": TODO=X,
  "y": TODO=Y,
  "z": TODO=Z,
  "r": 178,
  "g": 96,
  "b": 227,
  "enable": true,
  "type": "Normal",
  "origin": "journeymap",
  "dimensions": [
    0
  ],
  "persistent": true
}' | sed "s/TODO=X/$x/g" | sed "s/TODO=Y/$y/g" | sed "s/TODO=Z/$z/g" > "tmp_$x,$y,$z.json"
end

newwp $argv

