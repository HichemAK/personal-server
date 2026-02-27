#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install
source ~/scripts/.backup

CHHOTO_PASSWORD="$(openssl rand -base64 32 | tr -d '\n')"

./commons/install-docker.sh
./commons/install-nginx.sh

mkdir -p ~/scripts/setup-chhoto

cat > ~/scripts/setup-chhoto/compose.yaml <<EOF
services:
  chhoto-url:
    image: sintan1729/chhoto-url:latest
    container_name: chhoto-url
    restart: unless-stopped
    tty: true
    ports:
      - "127.0.0.1:4567:4567"
    environment:
      password: ${CHHOTO_PASSWORD}
      site_url: https://${CHHOTO_FQDN}
      db_url: /db/urls.sqlite
      slug_style: ${CHHOTO_SLUG_STYLE:-Pair}
      redirect_method: PERMANENT
      use_wal_mode: "True"
    volumes:
      - chhoto-db:/db

volumes:
  chhoto-db:
EOF

cd ~/scripts/setup-chhoto
docker compose pull
docker compose up -d
cd "$SCRIPT_DIR"

source ./setup-chhoto/config-nginx.sh
sudo systemctl reload nginx

if [ -n "${CU_BACKUP_MOUNT:-}" ]; then
    echo "${CU_BACKUP_CRON:-0 1 * * *} root bash ~/scripts/setup-chhoto/backup.sh >> /var/log/chhoto-backup.log 2>&1" \
        | sudo tee /etc/cron.d/chhoto-backup > /dev/null
    echo "✓ Chhoto URL backup cron installed (${CU_BACKUP_CRON:-0 1 * * *})"
fi

CREDS_FILE=/root/.credentials-chhoto
{
    echo "============ Chhoto URL ============"
    echo "  URL      : https://${CHHOTO_FQDN}"
    echo "  Password : ${CHHOTO_PASSWORD}"
} > "${CREDS_FILE}"
chmod 600 "${CREDS_FILE}"
