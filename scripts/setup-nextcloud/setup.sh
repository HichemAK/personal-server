#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install
source ~/scripts/.backup

./commons/install-nginx.sh
./commons/install-docker.sh

source ./setup-nextcloud/config-nginx.sh
./setup-nextcloud/config-fail2ban.sh
sudo systemctl reload nginx

./commons/install-yq.sh
cd setup-nextcloud

wget https://raw.githubusercontent.com/nextcloud/all-in-one/refs/heads/main/compose.yaml
yq -i '(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*8080:8080*")) = "127.0.0.1:8080:8080"' compose.yaml
yq -i 'del(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*80:80*"))' compose.yaml
yq -i 'del(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*8443:8443*"))' compose.yaml

if [ -n "${NC_BORG_RETENTION_POLICY:-}" ]; then
    yq -i ".services.nextcloud-aio-mastercontainer.environment.BORG_RETENTION_POLICY = \"${NC_BORG_RETENTION_POLICY}\"" override.yaml
fi
docker compose -f compose.yaml -f override.yaml up -d
cd ../

echo "IMPORTANT:"
echo "=========="
echo "Visit https://127.0.0.1:9909 for further instructions"
echo "Once you login in with you admin account in $NEXTCLOUD_FQDN, press Ctrl-C to continue..."

trap ':' INT
sleep infinity &
wait $! || true
trap - INT

source ./setup-nextcloud/config-nextcloud.sh

# ./commons/toggle-ssh-forwarding.sh no

# ./commons/port-traffic.sh allow 8080
