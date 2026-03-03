#!/bin/bash
# remove.sh — Remove Chhoto URL installation
set -euo pipefail

if ! docker ps -a --format '{{.Names}}' | grep -q '^chhoto-url$'; then
    echo "Chhoto URL does not appear to be installed (container not found). Nothing to remove."
    exit 0
fi

echo "=== Removing Chhoto URL ==="

cd ~/scripts/setup-chhoto
docker compose down -v 2>/dev/null || true
echo "✓ Removed container and database volume"

rm -f ~/scripts/setup-chhoto/compose.yaml
echo "✓ Removed compose.yaml"

rm -f /etc/nginx/conf.d/chhoto.conf
echo "✓ Removed nginx config"

rm -f /etc/cron.d/chhoto-backup
echo "✓ Removed backup cron"

rm -f /etc/fail2ban/filter.d/chhoto.local
rm -f /etc/fail2ban/jail.d/chhoto.local
fail2ban-client reload 2>/dev/null || true
echo "✓ Removed fail2ban jail"

systemctl reload nginx 2>/dev/null || true

echo "✓ Chhoto URL removed"
