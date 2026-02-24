#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install
source ~/scripts/.backup

./commons/install-docker.sh
./commons/install-nginx.sh

source ./setup-vaultwarden/install.sh

if [ -n "${VW_BACKUP_MOUNT:-}" ] && [ -n "${VW_BACKUP_ZIP_PASSWORD:-}" ]; then
    ./setup-vaultwarden/config-backup.sh
fi

source ./setup-vaultwarden/config-nginx.sh
sudo systemctl reload nginx

CREDS_FILE=/root/.credentials-vaultwarden
{
    echo "============ VaultWarden ============"
    echo "  Admin URL   : https://${VAULTWARDEN_FQDN}/admin"
    echo "  Admin token : ${VW_ADMIN_TOKEN}"
} > "${CREDS_FILE}"
chmod 600 "${CREDS_FILE}"
