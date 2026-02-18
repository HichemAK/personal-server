#!/bin/bash
# config-nginx.sh
set -euo pipefail

echo "=== Nginx Configuration for MailCow ==="
echo ""
echo -n "Enter the domain you use for MailCow (format: domain.com): "
read NC_FQDN

MAILCOW_HOSTNAME=mail.${NC_FQDN}

sudo mkdir -p /var/log/nginx

sudo tee /etc/nginx/sites-available/mailcow > /dev/null <<EOF
server {
    listen 80;
    server_name mail.${NC_FQDN} autodiscover.${NC_FQDN} autoconfig.${NC_FQDN};

    access_log /var/log/nginx/${NC_FQDN}.access.log;

    location / {
        proxy_pass http://127.0.0.1:8090;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

# Uncomment and fill in cert paths to enable HTTPS:
# server {
#     listen 443 ssl;
#     server_name mail.${NC_FQDN} autodiscover.${NC_FQDN} autoconfig.${NC_FQDN};
#
#     ssl_certificate     /etc/letsencrypt/live/${MAILCOW_HOSTNAME}/fullchain.pem;
#     ssl_certificate_key /etc/letsencrypt/live/${MAILCOW_HOSTNAME}/privkey.pem;
#
#     access_log /var/log/nginx/${NC_FQDN}.access.log;
#
#     location / {
#         proxy_pass http://127.0.0.1:8090;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;
#     }
# }
EOF

sudo ln -sf /etc/nginx/sites-available/mailcow /etc/nginx/sites-enabled/mailcow

sudo nginx -t
sudo systemctl reload nginx

echo "✓ Nginx configured for MailCow"
