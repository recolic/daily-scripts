#!/usr/bin/env bash

### rsandbox bash
# git clone https://github.com/ravinahp/flights-mcp
# cd flights-mcp
# curl -LsSf https://astral.sh/uv/install.sh | sh
# uv add --upgrade 'mcp[cli]>=1,<2'
# uv add --upgrade 'httpcore>=1.0.9'
# uv sync

source "$HOME/.local/bin/env"
export DUFFEL_API_KEY_LIVE="___TODO_PLEASE_ADD_ME___"
exec "$HOME/.local/bin/uv" --directory $HOME/flights-mcp run flights-mcp

#manual# vscode add mcp server: 
######## rsandbox bash /root/mcp-wrapper.sh
