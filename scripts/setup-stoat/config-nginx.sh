#!/bin/bash
# config-nginx.sh — Configure nginx as a reverse proxy in front of Stoat's
# Caddy instance (which listens on port 8880 in reverse-proxy mode).
set -euo pipefail

echo "=== Nginx Configuration for Stoat ==="

SERVER="${STOAT_FQDN}"
sudo rm -f /etc/nginx/conf.d/stoat.conf
sudo certbot certonly -d "$SERVER" --nginx --non-interactive --agree-tos --keep-until-expiring

sudo tee /etc/nginx/conf.d/stoat.conf > /dev/null <<EOF
map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ''      close;
}

server {
    listen 80;
    server_name $SERVER;
    location /.well-known/acme-challenge/ { root /var/www/_letsencrypt; }
    location / { return 301 https://\$host\$request_uri; }
}

server {
    listen 443 ssl http2;
    server_name $SERVER;

    ssl_certificate     /etc/letsencrypt/live/$SERVER/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SERVER/privkey.pem;

    access_log /var/log/nginx/stoat-access.log;

    proxy_set_header Host \$host;
    proxy_set_header X-Forwarded-Proto https;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    # WebSocket support (required for Stoat real-time events)
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection \$connection_upgrade;

    proxy_read_timeout 86400s;

    location / {
        proxy_pass http://127.0.0.1:8880;
    }
}
EOF

sudo nginx -t
echo "✓ Nginx configured for Stoat at https://${SERVER}"
