#!/bin/bash

echo "
[common]
bind_addr = 0.0.0.0
bind_port = 30999
authentication_method = token
token = $R_SEC_FRP_KEY
allow_ports = 30500-30899
" > /tmp/frps-tmp-acc.ini

frps -c /tmp/frps-tmp-acc.ini

