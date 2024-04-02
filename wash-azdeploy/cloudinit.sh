#!/bin/bash
#
DEBIAN_FRONTEND=noninteractive apt update -y ; DEBIAN_FRONTEND=noninteractive apt install -y docker.io
docker run -p 443:443 -p 8000:8000 -d --name washcrack --restart=always recolic/washcrack
