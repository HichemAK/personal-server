#!/bin/bash
# remove.sh — Remove VaultWarden installation
# Data at /mnt/storagebox/vw-data is PRESERVED.
set -euo pipefail

source /root/scripts/.install

if ! docker ps -a --format '{{.Names}}' | grep -q '^vaultwarden$'; then
    echo "VaultWarden does not appear to be installed (container not found). Nothing to remove."
    exit 0
fi

echo "=== Removing VaultWarden ==="

docker stop vaultwarden 2>/dev/null || true
docker rm vaultwarden 2>/dev/null || true
echo "✓ Removed vaultwarden container"

rm -f /etc/nginx/conf.d/vaultwarden.conf
echo "✓ Removed nginx config"

systemctl reload nginx 2>/dev/null || true

echo "✓ VaultWarden removed (data at /mnt/storagebox/vw-data is preserved)"
