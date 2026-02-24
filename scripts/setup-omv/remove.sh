#!/bin/bash
# remove.sh — Remove OpenMediaVault installation
set -euo pipefail

source ~/scripts/.install

if ! dpkg -l openmediavault &>/dev/null 2>&1; then
    echo "OpenMediaVault does not appear to be installed. Nothing to remove."
    exit 0
fi

echo "=== Removing OpenMediaVault ==="

apt-get purge -y openmediavault || true
apt-get autoremove -y || true

rm -f /etc/apt/sources.list.d/openmediavault.list
echo "✓ Removed OMV apt sources"

rm -f /usr/share/keyrings/openmediavault-archive-keyring.gpg
echo "✓ Removed OMV apt keyring"

apt-get update

echo "✓ OpenMediaVault removed"
