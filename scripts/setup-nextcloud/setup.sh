set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR

./setup-nextcloud/install-docker.sh


./commons/setup-mount.sh

# cd setup-nextcloud
# wget https://raw.githubusercontent.com/nextcloud/all-in-one/refs/heads/main/compose.yaml
# docker compose -f compose.yaml -f override.yaml up -d

# For Linux and without a web server or reverse proxy already in place:
export DATA_DIR="/mnt/storagebox/nextcloud"
# sudo chown -R 33:0 $DATA_DIR
# sudo chmod -R 750 $DATA_DIR

sudo docker run -d \
  --init \
  --sig-proxy=false \
  --name nextcloud-aio-mastercontainer \
  --restart always \
  --publish 80:80 \
  --publish 8080:8080 \
  --publish 8443:8443 \
  --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
  --volume /var/run/docker.sock:/var/run/docker.sock:ro \
  --env NEXTCLOUD_DATADIR="$DATA_DIR" \
  ghcr.io/nextcloud-releases/all-in-one:latest
  

echo "IMPORTANT:"
echo "=========="
IP=$(echo "$SSH_CONNECTION" | cut -d' ' -f3)
echo "Visit https://$IP:8080 for further instructions"