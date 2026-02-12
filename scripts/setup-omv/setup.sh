# Setup Script

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd $SCRIPT_DIR

# Install packages
sudo apt-get update
sudo apt-get install ufw -y

# Blocking everything except SSH
echo "🔒 Blocking all access except SSH..."
sudo ufw allow 22/tcp
sudo ufw --force enable
echo "✓ Firewall enabled - only SSH accessible"
echo ""

# Setup mount
./commons/setup-mount.sh

# Setup openvaultmedia
./setup-omv/install-omv.sh