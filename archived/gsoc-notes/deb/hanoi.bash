#!/bin/bash

height=$1
sleep_time=$2

[[ $height == '' ]] && echo 'Usage: ./hanoi.bash <height> [sleep_time = 0.6]' && exit 1
[[ $sleep_time == '' ]] && sleep_time=0.6

declare -a A=( $(seq 1 $height) )
declare -a B
declare -a C

function exchangeAC() {
    [[ ${A[0]} == '' ]] && [[ ${C[0]} == '' ]] && return 4 # done
    [[ ${A[0]} == '' ]] && A=( ${C[0]} ${A[@]} ) && C=( ${C[@]:1} ) && return 0
    [[ ${C[0]} == '' ]] || [[ `expr ${C[0]} \> ${A[0]}` == 1 ]] && C=( ${A[0]} ${C[@]} ) && A=( ${A[@]:1} ) && return 0
    A=( ${C[0]} ${A[@]} ) && C=( ${C[@]:1} ) && return 0
}
function exchangeAB() {
    [[ ${A[0]} == '' ]] && [[ ${B[0]} == '' ]] && return 4 # done
    [[ ${A[0]} == '' ]] && A=( ${B[0]} ${A[@]} ) && B=( ${B[@]:1} ) && return 0
    [[ ${B[0]} == '' ]] || [[ `expr ${B[0]} \> ${A[0]}` == 1 ]] && B=( ${A[0]} ${B[@]} ) && A=( ${A[@]:1} ) && return 0
    A=( ${B[0]} ${A[@]} ) && B=( ${B[@]:1} ) && return 0
}
function exchangeBC() {
    [[ ${B[0]} == '' ]] && [[ ${C[0]} == '' ]] && return 4 # done
    [[ ${B[0]} == '' ]] && B=( ${C[0]} ${B[@]} ) && C=( ${C[@]:1} ) && return 0
    [[ ${C[0]} == '' ]] || [[ `expr ${C[0]} \> ${B[0]}` == 1 ]] && C=( ${B[0]} ${C[@]} ) && B=( ${B[@]:1} ) && return 0
    B=( ${C[0]} ${B[@]} ) && C=( ${C[@]:1} ) && return 0
}



function show() {
    echo "A ${A[@]}"
    echo "B ${B[@]}"
    echo "C ${C[@]}"
    echo ''
}

function odd() {
    while true; do
        exchangeAC
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    
        exchangeAB
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    
        exchangeBC
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    done
}
function even() {
    while true; do
        exchangeAB
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    
        exchangeAC
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    
        exchangeBC
        [[ $? == 4 ]] && exit 0
        show && sleep $sleep_time
    done
}

[[ $((height % 2)) == 0 ]] && even || odd
