#!/bin/bash
# remove.sh — Remove Mailcow installation
set -euo pipefail

source ~/scripts/.install

if [ ! -d /opt/mailcow-dockerized ]; then
    echo "Mailcow does not appear to be installed (/opt/mailcow-dockerized not found). Nothing to remove."
    exit 0
fi

echo "=== Removing Mailcow ==="

cd /opt/mailcow-dockerized
docker compose down --remove-orphans 2>/dev/null || true

docker volume ls -q | grep '^mailcowdockerized_' | xargs -r docker volume rm
echo "✓ Removed mailcow volumes"

rm -rf /opt/mailcow-dockerized
echo "✓ Removed /opt/mailcow-dockerized"

rm -f /etc/cron.d/mailcow-backup
echo "✓ Removed mailcow backup cron"

rm -f /etc/nginx/conf.d/mailcow.conf
echo "✓ Removed nginx config"

systemctl reload nginx 2>/dev/null || true

echo "✓ Mailcow removed"
