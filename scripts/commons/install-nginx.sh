#!/bin/bash
# install-nginx.sh
set -euo pipefail

if nginx -v 2>/dev/null; then
  echo "nginx already installed!"
  exit 0
fi

sudo apt update
sudo apt install -y nginx

# Remove the default placeholder site
# sudo rm -f /etc/nginx/sites-enabled/default

sudo systemctl enable --now nginx
echo "✓ Nginx installed and running"
