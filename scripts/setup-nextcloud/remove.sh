#!/bin/bash
# remove.sh — Remove Nextcloud installation
set -euo pipefail

source ~/scripts/.install

mapfile -t NC_CONTAINERS < <(docker ps -a --format '{{.Names}}' | grep -E '^nextcloud-aio')

if [ ${#NC_CONTAINERS[@]} -eq 0 ]; then
    echo "Nextcloud does not appear to be installed (no containers found). Nothing to remove."
    exit 0
fi

echo "=== Removing Nextcloud ==="

for container in "${NC_CONTAINERS[@]}"; do
    docker stop "$container" 2>/dev/null || true
    docker rm "$container" 2>/dev/null || true
    echo "✓ Removed container: $container"
done

docker volume ls -q | grep '^nextcloud_aio_' | xargs -r docker volume rm
echo "✓ Removed nextcloud volumes"

rm -f /etc/nginx/conf.d/nextcloud.conf
echo "✓ Removed nginx config"

rm -f /etc/fail2ban/filter.d/nextcloud.local
rm -f /etc/fail2ban/jail.d/nextcloud.local
fail2ban-client reload 2>/dev/null || true
echo "✓ Removed fail2ban jail"

systemctl reload nginx 2>/dev/null || true

echo "✓ Nextcloud removed"
