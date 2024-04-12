#!/usr/bin/fish

set dummy_sessionid (loginctl list-sessions | grep dummy | grep '^ *[0-9]+ ' -oE | grep '[0-9]+' -oE)
set recolic_sessionid (loginctl list-sessions | grep recolic | grep '^ *[0-9]+ ' -oE | grep '[0-9]+' -oE)
test -z $recolic_sessionid ; or test -z $dummy_sessionid ; and echo "Failed to get two session id" ; and exit 1

echo "locking $recolic_sessionid, switching to $dummy_sessionid, try unlocking $dummy_sessionid"
sudo loginctl lock-session $recolic_sessionid
sudo loginctl unlock-session $dummy_sessionid
loginctl activate $dummy_sessionid

