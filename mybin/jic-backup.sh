#!/bin/bash
# sync current dir to storage.recolic as just-in-case backup

dirname=$(basename $(pwd))
rsync -avz --progress . storage.recolic:~/jic-backups/"$dirname"

