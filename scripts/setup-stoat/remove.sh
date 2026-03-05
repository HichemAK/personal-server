#!/bin/bash
# remove.sh — Remove the Stoat installation completely.
set -euo pipefail

if [ ! -d /data/stoat ]; then
    echo "Stoat does not appear to be installed (/data/stoat not found). Nothing to remove."
    exit 0
fi

echo "=== Removing Stoat ==="

cd /data/stoat
docker compose -f compose.yml -f compose.override.yml down 2>/dev/null || true
echo "✓ Stopped and removed containers"

cd /
rm -rf /data/stoat
echo "✓ Removed /data/stoat"

# Remove LiveKit firewall rules
iptables -D INPUT -p tcp --dport 7881 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p udp --dport 50000:50100 -j ACCEPT 2>/dev/null || true
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
echo "✓ Removed firewall rules"

rm -f /etc/nginx/conf.d/stoat.conf
echo "✓ Removed nginx config"
systemctl reload nginx 2>/dev/null || true

rm -f /etc/fail2ban/filter.d/stoat.local
rm -f /etc/fail2ban/jail.d/stoat.local
fail2ban-client reload 2>/dev/null || true

echo "✓ Stoat removed"
