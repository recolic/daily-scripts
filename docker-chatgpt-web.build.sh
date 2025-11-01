#!/bin/bash
# run in https://github.com/Niek/chatgpt-web
set -e

[ -d dist ] || sudo docker run --rm -v "$PWD":/app -w /app node:20-alpine sh -c "npm install && npm run build"

echo "FROM nginx:alpine
COPY . /usr/share/nginx/html" > /tmp/dockerfile
sudo docker build -t recolic/chatgpt-web -f /tmp/dockerfile dist

echo "Build success! Run it like: sudo docker run -d --restart=always --name chatgpt-web -p 5173:80 recolic/chatgpt-web"
