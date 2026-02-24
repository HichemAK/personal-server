#!/bin/bash
# Setup Script
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."
cd "$SCRIPT_DIR"

# Load configuration
source ~/scripts/.install

# Install packages
sudo apt-get update
sudo apt-get install ufw -y

# Blocking everything except SSH
echo "🔒 Blocking all access except SSH..."
sudo ufw allow 22/tcp
sudo ufw --force enable
echo "✓ Firewall enabled - only SSH accessible"
echo ""

# Setup openmediavault
./setup-omv/install-omv.sh
