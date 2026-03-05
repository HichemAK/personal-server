#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install
source ~/scripts/.security

./commons/install-docker.sh
./commons/install-nginx.sh

source setup-stoat/install.sh

cd "$SCRIPT_DIR"
./setup-stoat/config-fail2ban.sh
source ./setup-stoat/config-nginx.sh
sudo systemctl reload nginx

# Extract generated secrets and save credentials
CREDS_FILE=/root/.credentials-stoat
{
    echo "============ Stoat ============"
    echo "  URL         : https://${STOAT_FQDN}"
    echo "  Invite code : ${STOAT_INVITE_CODE}"
    echo ""
    echo "  ⚠  Back up the following secrets. If FILES_ENCRYPTION_KEY is lost,"
    echo "     all uploaded files become permanently inaccessible."
    echo ""
    grep -E "^(FILES_ENCRYPTION_KEY|PUSHD_VAPID_PRIVATEKEY|PUSHD_VAPID_PUBLICKEY|LIVEKIT_WORLDWIDE_KEY|LIVEKIT_WORLDWIDE_SECRET)=" \
        /data/stoat/secrets.env | sed 's/^/  /'
} > "${CREDS_FILE}"
chmod 600 "${CREDS_FILE}"
