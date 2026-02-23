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
    volumes:
      - ${VAULTWARDEN_DATA_DIR:-$HOME/vw-data}:/data/
    ports:
      - 127.0.0.1:8000:80
EOF

docker compose up -d
