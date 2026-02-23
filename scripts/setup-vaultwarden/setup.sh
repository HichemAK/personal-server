#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install

./commons/install-docker.sh
./commons/install-nginx.sh

source ./setup-vaultwarden/install.sh

source ./setup-vaultwarden/config-nginx.sh
sudo systemctl reload nginx

echo "Visit https://$VAULTWARDEN_FQDN/admin and configure VaultWarden."
echo "The admin token is '$VW_ADMIN_TOKEN' (DON'T FORGET TO STORE IT SOMEWHERE)."
