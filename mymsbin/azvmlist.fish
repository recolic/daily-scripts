#!/bin/fish
az vm list --output json | json2table /id -p | grep -iE 'recolic|bensl' | tr -d '|' | tr '/' ' '

