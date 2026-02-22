#!/bin/bash
# config-nginx.sh
set -euo pipefail

echo "=== Nginx Configuration for VaultWarden ==="
echo ""

sudo rm -f /etc/nginx/conf.d/vaultwarden.conf

SERVER="${VAULTWARDEN_FQDN}"
sudo rm -f /etc/nginx/conf.d/vaultwarden.conf
sudo certbot certonly -d $SERVER --nginx --non-interactive --agree-tos --keep-until-expiring


sudo tee /etc/nginx/conf.d/vaultwarden.conf > /dev/null <<EOF
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

  client_max_body_size 100m;
  proxy_set_header Host \$host;
  proxy_set_header X-Forwarded-Proto https;
  proxy_set_header X-Real-IP \$remote_addr;

  location /notifications/hub/negotiate { proxy_pass http://127.0.0.1:8000; }
  location /notifications/hub          { proxy_set_header Upgrade \$http_upgrade; proxy_set_header Connection "upgrade"; proxy_pass http://127.0.0.1:8000; }
  location / { proxy_pass http://127.0.0.1:8000; }
}
EOF

sudo nginx -t

echo "✓ Nginx configured for VaultWarden"
