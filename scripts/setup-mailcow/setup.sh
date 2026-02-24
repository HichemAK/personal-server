#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install
source ~/scripts/.backup

./commons/install-nginx.sh

sudo apt update
sudo apt install -y git openssl curl gawk coreutils grep jq

umask 0022

# Idempotency: skip clone if already present
if [ ! -d /opt/mailcow-dockerized ]; then
    cd /opt
    git clone https://github.com/mailcow/mailcow-dockerized
fi
cd /opt/mailcow-dockerized
rm -f mailcow.conf

# Export vars so generate_config.sh runs non-interactively
export MAILCOW_HOSTNAME="${MAILCOW_FQDN}"
export MAILCOW_TZ="${MAILCOW_TZ}"
export MAILCOW_BRANCH="master"
export ENABLE_IPV6=true
export FORCE=1
./generate_config.sh

# Bind to localhost only — Nginx will be the public-facing proxy
sed -i 's/^HTTP_BIND=.*/HTTP_BIND=127.0.0.1/' mailcow.conf
sed -i 's/^HTTP_PORT=.*/HTTP_PORT=8090/' mailcow.conf
sed -i 's/^HTTPS_BIND=.*/HTTPS_BIND=127.0.0.1/' mailcow.conf
sed -i 's/^HTTPS_PORT=.*/HTTPS_PORT=8443/' mailcow.conf
sed -i 's/^HTTP_REDIRECT=.*/HTTP_REDIRECT=n/' mailcow.conf
sed -i 's/^DOCKER_COMPOSE_VERSION=.*/DOCKER_COMPOSE_VERSION=native/' mailcow.conf
sed -i 's/^SKIP_CLAMD=.*/SKIP_CLAMD=y/' mailcow.conf

# if [ -n "${MAILCOW_DATA_DIR:-}" ]; then
#     sed -i "s|^MAILDIR_SUB=.*|MAILDIR_SUB=${MAILCOW_DATA_DIR}|" mailcow.conf
# fi

# Disable Mailcow's built-in Let's Encrypt
# sed -i 's/^SKIP_LETS_ENCRYPT=.*/SKIP_LETS_ENCRYPT=y/' mailcow.conf

# echo "You can change the /opt/mailcow-dockerized/mailcow.conf to configure MailCow."
# echo "Press Ctrl-C to continue..."
# trap ':' INT
# sleep infinity &
# wait $! || true
# trap - INT

docker compose pull
docker compose up -d

ADMIN_CREDENTIALS="$(./helper-scripts/mailcow-reset-admin.sh)"

# echo "Visit https://127.0.0.1:9909/admin and change the admin password. The default credentials are 'admin' and 'moohoo' for username and password respectively."
# echo "Only then, press Ctrl-C to continue..."
# trap ':' INT
# sleep infinity &
# wait $! || true
# trap - INT

if [ -n "${MC_BACKUP_MOUNT:-}" ]; then
    echo "${MC_BACKUP_CRON:-0 3 * * *} root bash ~/scripts/setup-mailcow/backup.sh >> /var/log/mailcow-backup.log 2>&1" \
        | sudo tee /etc/cron.d/mailcow-backup > /dev/null
    echo "✓ Mailcow backup cron installed (${MC_BACKUP_CRON:-0 3 * * *})"
fi

cd "$SCRIPT_DIR"
source ./setup-mailcow/config-nginx.sh
sudo systemctl reload nginx

CREDS_FILE=/root/.credentials-mailcow
{
    echo "============ Mailcow ============"
    echo "Admin URL : https://${MAILCOW_FQDN}/admin"
    echo "${ADMIN_CREDENTIALS}"
} > "${CREDS_FILE}"
chmod 600 "${CREDS_FILE}"
