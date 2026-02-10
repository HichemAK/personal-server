#!/bin/bash
# setup-mount.sh
set -euo pipefail

echo "=== SFTP Storage Mount Setup ==="
echo ""

# Get credentials
echo -n "Enter username (e.g., u123456): "
read SFTP_USER

echo -n "Enter server address (e.g., u123456.your-storagebox.de): "
read SERVER_ADDRESS

# echo -n "SSH key path (default: /root/server/id_ed25519): "
# read SSH_KEY
SSH_KEY=${SSH_KEY:-/root/server/id_ed25519}

SSH_PORT=23  # Hetzner default

# Ensure correct permissions
sudo chmod 600 "$SSH_KEY"
echo "✓ SSH key found at $SSH_KEY"

# Create mount point
MOUNT_POINT="/mnt/storagebox"
sudo mkdir -p "$MOUNT_POINT"

# Add to fstab
if ! grep -q "$MOUNT_POINT" /etc/fstab; then
    # Add StrictHostKeyChecking=no to fstab entry
    echo "${SFTP_USER}@${SERVER_ADDRESS}:/home $MOUNT_POINT fuse.sshfs IdentityFile=$SSH_KEY,port=$SSH_PORT,StrictHostKeyChecking=no,_netdev,allow_other,default_permissions 0 0" | sudo tee -a /etc/fstab
    echo "✓ Added to /etc/fstab"
fi

# Mount
sudo systemctl daemon-reload
sudo mount "$MOUNT_POINT"

echo "✓ Storage mounted at $MOUNT_POINT"
echo "✓ Will auto-mount on boot"