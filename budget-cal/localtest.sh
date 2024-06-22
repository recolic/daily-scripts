#!/bin/bash
sudo rm -rf /var/www/html/ltest
sudo mkdir -p /var/www/html/ltest
sudo cp -r * /var/www/html/ltest/
sudo chmod 777 /var/www/html/ltest/

echo "http://localhost/ltest"

