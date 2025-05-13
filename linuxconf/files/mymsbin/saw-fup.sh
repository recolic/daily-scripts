#!/bin/bash

# Variables
LOCAL_FILE="$1"                                # File to process (passed as an argument)
REMOTE_SCP_DEST="remote.hms.r:/mnt/fsdisk/nfs/tmp/saw-shared.file"  # SCP destination
REMOTE_NFS_DEST="$HOME/nfs/tmp/saw-shared.file"                     # Local NFS destination

[[ "$1" = "" ]] && echo "Usage: $0 <localfile path>" && exit 1

# Check if the local NFS directory exists
if [ -d "$(dirname "$REMOTE_NFS_DEST")" ]; then
    echo "NFS directory exists locally. Moving file..."
    mv "$LOCAL_FILE" "$REMOTE_NFS_DEST" && exit 0 || echo "Failed to move file locally to NFS directory."
fi

echo "NFS doesn't work. Using SCP to transfer file..."
scp "$LOCAL_FILE" "$REMOTE_SCP_DEST"
if [ $? -eq 0 ]; then
    echo "File successfully transferred to remote server via SCP. Deleting original..."
    rm -f "$LOCAL_FILE"
else
    echo "SCP failed. Original file retained."
    exit 1
fi

