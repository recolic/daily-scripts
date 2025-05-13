#!/bin/bash
# Minecraft client updater by Recolic

UPDATER_INFO_DOWNLOAD_URL="https://tdl.recolic.net/"
VERSION_FROM='1.0.1'
VERSION_TO='1.0.2'

function assert () {
    $1
    RET_VAL=$?
    if [ $RET_VAL != 0 ]; then
        echo "Assertion failed: $1 returns $RET_VAL."
        if [ "$2" != "" ]; then
            echo "Message: $2"
        fi
        exit $RET_VAL
    fi
}

function update_proc () {
    echo 'Starting update...'
    
    
}

TARGET_PATH=$1
if [ "$TARGET_PATH" == "" ]; then
    echo "Usage: $0 some/path/.minecraft"
    exit 2
fi
if test -d "$TARGET_PATH"; then
    if ps -aux | grep '\.minecraft[^\[]' | egrep '(java)|(javaw)'; then
        echo 'Please terminate Minecraft before updating your client'
        exit 6
    fi
    test -f "$TARGET_PATH/cli-updater.info"
    if [ $? != 0 ]; then
        assert "wget -O $TARGET_PATH/cli-updater.info $UPDATER_INFO_DOWNLOAD_URL" "Download failed."
    fi
    assert "grep version=$VERSION_FROM $TARGET_PATH/cli-updater.info" "Origin version is not correct or your cli-updater.info is broken."
    update_proc
    # Success if running here.
    assert "perl -pi -e 's/version=$VERSION_FROM/version=$VERSION_TO/g' $TARGET_PATH/cli-updater.info" "Update is successfully done but error occurred while writing config-file"
    echo "Done."
    exit 0
else
    echo 'Path is invalid.'
    exit 1
fi



# AutoThrottleDownTank
