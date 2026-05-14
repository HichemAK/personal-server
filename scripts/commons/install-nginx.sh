#!/bin/bash
# install-nginx.sh
set -euo pipefail

if nginx -v 2>/dev/null; then
  echo "nginx already installed!"
  exit 0
fi

sudo apt install curl gnupg2 ca-certificates lsb-release debian-archive-keyring certbot python3-certbot-nginx -y
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/debian `lsb_release -cs` nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx
sudo apt update
sudo apt install nginx -y

# --- auto-restart setup ---
sudo systemctl enable nginx

sudo mkdir -p /etc/systemd/system/nginx.service.d
sudo tee /etc/systemd/system/nginx.service.d/override.conf > /dev/null <<'EOF'
[Service]
Restart=always
RestartSec=30s
EOF

sudo systemctl daemon-reload
sudo systemctl restart nginx

echo "✓ Nginx installed"
