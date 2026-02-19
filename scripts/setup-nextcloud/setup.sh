set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR


./commons/install-nginx.sh
./commons/install-docker.sh

source ./commons/setup-mount.sh
mkdir /mnt/storagebox/nextcloud || true

./setup-nextcloud/config-nginx.sh
sudo systemctl start nginx

wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq && chmod +x /usr/local/bin/yq
cd setup-nextcloud

wget https://raw.githubusercontent.com/nextcloud/all-in-one/refs/heads/main/compose.yaml
yq -i '(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*8080:8080*")) = "127.0.0.1:8080:8080"' compose.yaml
yq -i 'del(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*80:80*"))' compose.yaml
yq -i 'del(.services.nextcloud-aio-mastercontainer.ports[] | select(. == "*8443:8443*"))' compose.yaml
docker compose -f compose.yaml -f override.yaml up -d
cd ../

# For Linux and without a web server or reverse proxy already in place:
# export DATA_DIR="/mnt/storagebox/nextcloud"
# sudo chown -R 33:0 $DATA_DIR
# sudo chmod -R 750 $DATA_DIR

# sudo docker run -d \
#   --init \
#   --sig-proxy=false \
#   --name nextcloud-aio-mastercontainer \
#   --restart always \
#   --publish 80:80 \
#   --publish 8080:8080 \
#   --publish 8443:8443 \
#   --volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
#   --volume /var/run/docker.sock:/var/run/docker.sock:ro \
#   ghcr.io/nextcloud-releases/all-in-one:latest
  

echo "IMPORTANT:"
echo "=========="
IP=$(echo "$SSH_CONNECTION" | cut -d' ' -f3)
echo "Visit https://127.0.0.1:9909 for further instructions"
echo "Once you login in you admin account in nextcloud.yourdomain.com, press Ctrl-C to continue..."

trap ':' INT
sleep infinity &
wait $! || true
trap - INT

source ./setup-nextcloud/config-nextcloud.sh

# ./commons/toggle-ssh-forwarding.sh no

# ./commons/port-traffic.sh allow 8080