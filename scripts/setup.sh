# Setup Script

set -euo pipefail  # Exit on error, undefined variables

# Secure the scripts folder
./secure-folder.sh

# Install packages
sudo apt update
sudo apt install cifs-utils ufw -y

# Blocking everything except SSH
echo "🔒 Blocking all access except SSH..."
sudo ufw allow 22/tcp
sudo ufw --force enable
echo "✓ Firewall enabled - only SSH accessible"
echo ""

# Setup mount
./setup-mount.sh

# Setup openvaultmedia
./setup-omv.sh