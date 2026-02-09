#!/bin/bash
# setup-mount.sh

set -euo pipefail  # Exit on error, undefined variables

# Secure the script itself
chmod 700 "$0"

echo "=== Network Storage Mount Setup ==="

# Get credentials securely (not stored in script)
read -p "Enter username: " SAMBA_USER
read -sp "Enter password: " SAMBA_PASS
read -p "Enter server address: " SERVER_ADDRESS
echo

# Validate inputs
if [[ -z "$SAMBA_USER" ]] || [[ -z "$SAMBA_PASS" ]] || [[ -z "$SERVER_ADDRESS" ]]; then
    echo "Error: Username, password, and server address of the Storage Box are required (See Hetzner Console)"
    exit 1
fi

# Create credentials file
sudo bash -c "cat > /root/.smbcredentials << EOF
username=$SAMBA_USER
password=$SAMBA_PASS
EOF"

# Clear variables from memory
unset SAMBA_USER
unset SAMBA_PASS

# Secure the credentials file
sudo chmod 600 /root/.smbcredentials
sudo chown root:root /root/.smbcredentials

echo "✓ Credentials file created securely at /root/.smbcredentials"

# Create mount point
sudo mkdir -p /mnt/network-storage

# Add to fstab if not already there
if ! grep -q "network-storage" /etc/fstab; then
    echo "//$SERVER_ADDRESS/backup /mnt/network-storage cifs credentials=/root/.smbcredentials,iocharset=utf8,_netdev 0 0" | sudo tee -a /etc/fstab
    echo "✓ Added mount to /etc/fstab"
fi

# Mount immediately
sudo mount /mnt/network-storage
echo "✓ Storage mounted successfully"
