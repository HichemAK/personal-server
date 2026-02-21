set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR

./commons/install-nginx.sh

source ./commons/setup-mount.sh

source ./setup-vaultwarden/install.sh

source ./setup-vaultwarden/config-nginx.sh
sudo systemctl stop nginx || true
sudo systemctl start nginx

echo "Visit https://vm.$DOMAIN/admin and configure VaultWarden. The admin token is '$VW_ADMIN_TOKEN' (DON'T FORGET TO STORE IT SOMEWHERE)."
