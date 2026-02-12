SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd $SCRIPT_DIR

./install-docker.sh


./setup-mount.sh

wget https://raw.githubusercontent.com/nextcloud/all-in-one/refs/heads/main/compose.yaml

docker compose up -f compose.yaml -f override.yaml -d