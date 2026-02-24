#!/bin/bash
# remove.sh — Remove VaultWarden installation
set -euo pipefail

source ~/scripts/.install

if ! docker ps -a --format '{{.Names}}' | grep -q '^vaultwarden$'; then
    echo "VaultWarden does not appear to be installed (container not found). Nothing to remove."
    exit 0
fi

echo "=== Removing VaultWarden ==="

docker stop vaultwarden-backup 2>/dev/null || true
docker rm vaultwarden-backup 2>/dev/null || true
docker stop vaultwarden 2>/dev/null || true
docker rm vaultwarden 2>/dev/null || true
echo "✓ Removed containers"

docker volume rm vaultwarden-rclone-data 2>/dev/null || true
echo "✓ Removed rclone config volume"

rm -f ~/scripts/compose.yaml
echo "✓ Removed compose.yaml"

rm -rf $VAULTWARDEN_DATA_DIR
echo "✓ Removed vault warden data"


rm -f /etc/nginx/conf.d/vaultwarden.conf
echo "✓ Removed nginx config"


systemctl reload nginx 2>/dev/null || true

echo "✓ VaultWarden removed"
