#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

export VW_ADMIN_TOKEN="$(openssl rand -hex 24)"

sudo tee compose.yaml > /dev/null <<EOF
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://${VAULTWARDEN_FQDN}"
      ADMIN_TOKEN: "$VW_ADMIN_TOKEN"
      SIGNUPS_ALLOWED: false
      LOG_FILE: /data/vaultwarden.log
    volumes:
      - ${VAULTWARDEN_DATA_DIR:-$HOME/vw-data}:/data/
    ports:
      - 127.0.0.1:8000:80
EOF

if [ -n "${VW_BACKUP_MOUNT:-}" ] && [ -n "${VW_BACKUP_ZIP_PASSWORD:-}" ]; then
    sudo tee -a compose.yaml > /dev/null <<EOF

  vaultwarden-backup:
    image: ttionya/vaultwarden-backup:latest
    container_name: vaultwarden-backup
    restart: unless-stopped
    volumes_from:
      - vaultwarden
    volumes:
      - vaultwarden-rclone-data:/config/
    environment:
      DATA_DIR: "/data"
      RCLONE_REMOTE_NAME: "VaultWardenBackup"
      RCLONE_REMOTE_DIR: "${VW_BACKUP_RCLONE_DIR:-/VaultWardenBackup}"
      CRON: "${VW_BACKUP_CRON:-0 2 * * *}"
      ZIP_PASSWORD: "${VW_BACKUP_ZIP_PASSWORD}"
      BACKUP_KEEP_DAYS: "${VW_BACKUP_KEEP_DAYS:-30}"
      TIMEZONE: "${VW_BACKUP_TZ:-UTC}"
    depends_on:
      - vaultwarden

volumes:
  vaultwarden-rclone-data:
    external: true
    name: vaultwarden-rclone-data
EOF
    docker volume create vaultwarden-rclone-data 2>/dev/null || true
fi

docker compose pull
docker compose up -d
