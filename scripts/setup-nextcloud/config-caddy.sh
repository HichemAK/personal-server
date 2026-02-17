#!/bin/bash
# config-caddy.sh
set -euo pipefail

echo "=== Caddy Configuration for Nextcloud ==="
echo ""
echo -n "Enter the FQDN for Nextcloud (e.g., cloud.yourdomain.com): "
read NC_FQDN

cat <<EOF | sudo tee -a /etc/caddy/Caddyfile > /dev/null

# Nextcloud AIO
https://${NC_FQDN}:443 {
    header Strict-Transport-Security max-age=31536000;
    reverse_proxy localhost:11000
}
EOF

sudo systemctl reload caddy
echo "✓ Caddy configured for Nextcloud at https://${NC_FQDN}"
