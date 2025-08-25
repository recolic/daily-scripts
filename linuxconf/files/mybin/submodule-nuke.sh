#!/bin/bash

git submodule foreach --recursive git reset --hard
git submodule foreach --recursive git clean -fdx
git submodule update --init --recursive --force

