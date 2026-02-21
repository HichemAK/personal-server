set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR

export VW_ADMIN_TOKEN="$(openssl rand -hex 24)"

echo -n "Enter the domain you wish to use for Vault Warden (format: domain.com): "
read DOMAIN
sudo tee compose.yaml > /dev/null <<EOF
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "https://vw.${DOMAIN}"
      ADMIN_TOKEN: "$VW_ADMIN_TOKEN"
      SIGNUPS_ALLOWED: false
    volumes:
      - /mnt/storagebox/vw-data/:/data/
    ports:
      - 127.0.0.1:8000:80
EOF

docker compose up -d