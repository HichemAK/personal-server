#!/bin/bash
# install.sh — Clone stoatchat/self-hosted, generate config, open firewall ports,
# and start the Stoat Docker Compose stack.
set -euo pipefail

echo "=== Installing Stoat ==="

# Install git if not already present
if ! command -v git &>/dev/null; then
    apt-get install -y git
fi

# Clone the repo (idempotent)
if [ ! -d /data/stoat ]; then
    mkdir -p /data
    git clone https://github.com/stoatchat/self-hosted /data/stoat
else
    echo "  /data/stoat already exists, skipping clone"
fi

cd /data/stoat

# Generate Revolt.toml, secrets.env, .env.web, livekit.yml, compose.override.yml
# The override configures Caddy to listen on port 8880 for reverse-proxy mode
chmod +x ./generate_config.sh
./generate_config.sh "${STOAT_FQDN}"

# Open LiveKit ports (TCP + UDP — cannot be proxied by nginx)
# Install iptables-persistent so rules survive reboots
DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Remove existing rules for these ports to avoid duplicates on reinstall
iptables -D INPUT -p tcp --dport 7881 -j ACCEPT 2>/dev/null || true
iptables -D INPUT -p udp --dport 50000:50100 -j ACCEPT 2>/dev/null || true

iptables -A INPUT -p tcp --dport 7881 -j ACCEPT
iptables -A INPUT -p udp --dport 50000:50100 -j ACCEPT
iptables-save > /etc/iptables/rules.v4
echo "✓ Firewall rules added for LiveKit (7881/tcp, 50000-50100/udp)"

# Enforce invite-only registration
cat >> Revolt.toml <<'EOF'

[api.registration]
# Whether an invite should be required for registration
# See https://github.com/revoltchat/self-hosted#making-your-instance-invite-only
invite_only = true
EOF
echo "✓ Registration set to invite-only"

# Append SMTP configuration
cat >> Revolt.toml <<EOF

[api.smtp]
# Email server configuration for verification
# Defaults to no email verification (host field is empty)
host = "${STOAT_SMTP_HOST:-}"
username = "${STOAT_SMTP_USERNAME:-}"
password = "${STOAT_SMTP_PASSWORD:-}"
from_address = "${STOAT_SMTP_FROM:-}"
# reply_to = "noreply@example.com"
# port = 587
# use_tls = true
EOF
echo "✓ SMTP configuration appended"

# Pull images and start
docker compose -f compose.yml -f compose.override.yml pull
docker compose -f compose.yml -f compose.override.yml up -d

# Wait for MongoDB to be ready before inserting the invite
echo "Waiting for MongoDB..."
until docker compose exec -T database mongosh --quiet --eval "db.adminCommand('ping')" &>/dev/null; do
    sleep 1
done

# Generate and insert a random invite code
STOAT_INVITE_CODE="$(openssl rand -hex 16)"
docker compose exec -T database mongosh revolt --quiet \
    --eval "db.invites.insertOne({ _id: \"${STOAT_INVITE_CODE}\" })"
export STOAT_INVITE_CODE
echo "✓ Invite code created"

echo "✓ Stoat started"
