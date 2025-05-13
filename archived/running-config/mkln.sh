#!/bin/bash

[[ $1 == '' ]] && echo 'Usage: ./this.sh <file to create ln>' && exit 1

sudo ln -s /home/recolic/sh/running-config/$1 /usr/user-bin/$1
