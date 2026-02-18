#!/bin/bash
# config-nginx.sh
set -euo pipefail

echo "=== Nginx Configuration for Nextcloud ==="
echo ""
echo -n "Enter the FQDN for Nextcloud (e.g., cloud.yourdomain.com): "
read NC_FQDN

sudo tee /etc/nginx/sites-available/nextcloud > /dev/null <<EOF
server {
    listen 80;
    server_name ${NC_FQDN};

    add_header Strict-Transport-Security "max-age=31536000" always;

    location / {
        proxy_pass http://localhost:11000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Uncomment and fill in cert paths to enable HTTPS:
# server {
#     listen 443 ssl;
#     server_name ${NC_FQDN};
#
#     ssl_certificate     /etc/letsencrypt/live/${NC_FQDN}/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/${NC_FQDN}/privkey.pem;
#
#     add_header Strict-Transport-Security "max-age=31536000" always;
#
#     location / {
#         proxy_pass http://localhost:11000;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#     }
# }
EOF

sudo ln -sf /etc/nginx/sites-available/nextcloud /etc/nginx/sites-enabled/nextcloud

sudo nginx -t
sudo systemctl reload nginx
echo "✓ Nginx configured for Nextcloud at http://${NC_FQDN}"
