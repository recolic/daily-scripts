#!/bin/bash

function randstr () { 
    < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32};echo;
}

randstr
randstr
