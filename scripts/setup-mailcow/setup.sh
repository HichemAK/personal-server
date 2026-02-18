set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR

./commons/install-caddy.sh

sudo apt update
sudo apt install -y git openssl curl gawk coreutils grep jq

umask 0022
cd /opt
git clone https://github.com/mailcow/mailcow-dockerized
cd mailcow-dockerized

./generate_config.sh

# Bind to localhost only — Caddy will be the public-facing proxy
sed -i 's/^HTTP_BIND=.*/HTTP_BIND=127.0.0.1/' mailcow.conf
sed -i 's/^HTTP_PORT=.*/HTTP_PORT=8090/' mailcow.conf
sed -i 's/^HTTPS_BIND=.*/HTTPS_BIND=127.0.0.1/' mailcow.conf
sed -i 's/^HTTPS_PORT=.*/HTTPS_PORT=8443/' mailcow.conf

# Disable Mailcow's built-in Let's Encrypt — Caddy handles TLS now
sed -i 's/^SKIP_LETS_ENCRYPT=.*/SKIP_LETS_ENCRYPT=y/' mailcow.conf

echo "You can change the /opt/mailcow-dockerized/mailcow.conf to configure MailCow."
echo "Press Ctrl-C to continue..."
trap ':' INT
sleep infinity &
wait $! || true
trap - INT

docker compose pull
docker compose up -d

echo "Visit https://127.0.0.1:9909/admin and change the admin password. The default credentials are 'admin' and 'moohoo' for username and password respectively."
echo "Only then, press Ctrl-C to continue..."
trap ':' INT
sleep infinity &
wait $! || true
trap - INT


./setup-mailcow/config-caddy.sh