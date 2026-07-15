#!/usr/bin/env bash

### rsandbox bash
# git clone https://github.com/ravinahp/flights-mcp
# cd flights-mcp
# curl -LsSf https://astral.sh/uv/install.sh | sh
#manual# add "httpcore>=1.0.9" into pyproject.toml
# uv sync

source "$HOME/.local/bin/env"
export DUFFEL_API_KEY_LIVE="___TODO_PLEASE_ADD_ME___"
exec "$HOME/.local/bin/uv" --directory /root/flights-mcp run flights-mcp

#manual# vscode add mcp server: 
######## rsandbox bash /root/mcp-wrapper.sh
