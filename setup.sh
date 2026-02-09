# Setup Script

set -euo pipefail  # Exit on error, undefined variables

# Secure the scripts folder
./secure-folder.sh

# Install packages
sudo apt update
sudo apt install cifs-utils -y

# Setup mount
./setup-mount.sh

# Setup openvaultmedia
