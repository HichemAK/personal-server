#!/bin/bash
# setup-mount.sh
set -euo pipefail

MOUNT_POINT="/mnt/storagebox"

echo "=== Storage Mount Setup ==="
echo ""
echo "Select mount type:"
echo "  1) SFTP (recommended)"
echo "  2) SMB"
echo "  3) WebDAV"
echo "  4) Skip (no external drive)"
echo ""
echo -n "Choice [1-4]: "
read MOUNT_CHOICE

if [ "$MOUNT_CHOICE" = "4" ]; then
    echo "Skipping storage mount setup."
    return 0
fi

echo -n "Enter username (e.g., u123456): "
read MOUNT_USER

echo -n "Enter server address (e.g., u123456.your-storagebox.de): "
read MOUNT_ADDRESS

sudo mkdir -p "$MOUNT_POINT"

case "$MOUNT_CHOICE" in
    1)
        echo "=== SFTP Mount ==="

        echo -n "Enter SFTP password: "
        read -s SFTP_PASS
        echo ""

        sudo apt-get install -y sshfs

        SSH_PORT=23

        if ! grep -q "$MOUNT_POINT" /etc/fstab; then
            echo "${MOUNT_USER}@${MOUNT_ADDRESS}:/home $MOUNT_POINT fuse.sshfs port=$SSH_PORT,password_stdin,StrictHostKeyChecking=no,_netdev,allow_other,default_permissions 0 0" | sudo tee -a /etc/fstab
            echo "✓ Added to /etc/fstab"
        fi

        echo "$SFTP_PASS" | sudo sshfs "${MOUNT_USER}@${MOUNT_ADDRESS}:/home" "$MOUNT_POINT" -o port=$SSH_PORT,password_stdin,StrictHostKeyChecking=no,allow_other,default_permissions
        echo "✓ SFTP mounted with password"
        ;;
    2)
        echo "=== SMB Mount ==="

        echo -n "Enter SMB password: "
        read -s SMB_PASS
        echo ""

        sudo apt-get install -y cifs-utils

        CRED_FILE="/etc/samba/credentials_storagebox"
        sudo mkdir -p /etc/samba
        sudo tee "$CRED_FILE" > /dev/null <<EOF
username=$MOUNT_USER
password=$SMB_PASS
EOF
        sudo chmod 600 "$CRED_FILE"
        echo "✓ Credentials stored"

        if ! grep -q "$MOUNT_POINT" /etc/fstab; then
            echo "//${MOUNT_ADDRESS}/backup $MOUNT_POINT cifs credentials=$CRED_FILE,_netdev 0 0" | sudo tee -a /etc/fstab
            echo "✓ Added to /etc/fstab"
        fi
        ;;
    3)
        echo "=== WebDAV Mount ==="

        echo -n "Enter WebDAV password: "
        read -s WEBDAV_PASS
        echo ""

        sudo apt-get install -y davfs2

        WEBDAV_URL="https://${MOUNT_ADDRESS}"
        DAVFS_SECRETS="/etc/davfs2/secrets"

        if ! grep -q "$WEBDAV_URL" "$DAVFS_SECRETS" 2>/dev/null; then
            echo "$WEBDAV_URL $MOUNT_USER $WEBDAV_PASS" | sudo tee -a "$DAVFS_SECRETS" > /dev/null
            sudo chmod 600 "$DAVFS_SECRETS"
            echo "✓ Credentials stored"
        fi

        if ! grep -q "$MOUNT_POINT" /etc/fstab; then
            echo "$WEBDAV_URL $MOUNT_POINT davfs _netdev,auto 0 0" | sudo tee -a /etc/fstab
            echo "✓ Added to /etc/fstab"
        fi
        ;;
    *)
        echo "Invalid choice"
        return 1
        ;;
esac

sudo systemctl daemon-reload

if [ "$MOUNT_CHOICE" != "1" ]; then
    sudo mount "$MOUNT_POINT"
fi

echo "✓ Storage mounted at $MOUNT_POINT"
echo "✓ Will auto-mount on boot"
