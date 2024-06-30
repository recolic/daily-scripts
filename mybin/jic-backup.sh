#!/bin/bash
# sync current dir to storage.recolic as just-in-case backup

dirname=$(basename $(pwd))
echo "Uploading to storage.recolic:$dirname"
rsync -avz --progress . storage.recolic:~/jic-backups/"$dirname"

