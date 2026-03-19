#!/bin/bash
# For cursor AI. Run command in sandbox (dedicated linux VM)

# TODO TODO
ssh -p 30111 r@proxy.recolic.net "$@"
exit $?
