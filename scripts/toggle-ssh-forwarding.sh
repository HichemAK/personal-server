#!/bin/bash
# Script: toggle_ssh_forwarding.sh
# Usage: ./toggle_ssh_forwarding.sh <true|false>

set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root or with sudo"
    exit 1
fi

# Check argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <true|false|yes|no|1|0|enable|disable>"
    echo ""
    echo "Examples:"
    echo "  $0 true     # Enable port forwarding"
    echo "  $0 false    # Disable port forwarding"
    exit 1
fi

# Parse input to boolean
INPUT=$(echo "$1" | tr '[:upper:]' '[:lower:]')

case "$INPUT" in
    true|yes|1|enable|on)
        ACTION="yes"
        ACTION_TEXT="enabled"
        ;;
    false|no|0|disable|off)
        ACTION="no"
        ACTION_TEXT="disabled"
        ;;
    *)
        echo "Error: Invalid input '$1'"
        echo "Valid options: true, false, yes, no, 1, 0, enable, disable"
        exit 1
        ;;
esac

# Backup config
CONFIG_FILE="/etc/ssh/sshd_config"
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "Backing up SSH config to $BACKUP_FILE"
cp "$CONFIG_FILE" "$BACKUP_FILE"

# Modify config
echo "Setting AllowTcpForwarding to $ACTION..."

if grep -q "^AllowTcpForwarding" "$CONFIG_FILE"; then
    # Line exists and is active - replace it
    sed -i "s/^AllowTcpForwarding.*/AllowTcpForwarding $ACTION/" "$CONFIG_FILE"
    echo "✓ Updated existing AllowTcpForwarding directive"
elif grep -q "^#AllowTcpForwarding" "$CONFIG_FILE"; then
    # Line exists but is commented - uncomment and set value
    sed -i "s/^#AllowTcpForwarding.*/AllowTcpForwarding $ACTION/" "$CONFIG_FILE"
    echo "✓ Uncommented and set AllowTcpForwarding"
else
    # Line doesn't exist - add it
    echo "" >> "$CONFIG_FILE"
    echo "AllowTcpForwarding $ACTION" >> "$CONFIG_FILE"
    echo "✓ Added AllowTcpForwarding directive"
fi

# Verify change
echo ""
echo "Current setting:"
grep "^AllowTcpForwarding" "$CONFIG_FILE"

# Test SSH config syntax
echo ""
echo "Testing SSH configuration syntax..."
if sshd -t; then
    echo "✓ Configuration syntax is valid"
else
    echo "✗ Configuration syntax error!"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    echo "Backup restored. No changes applied."
    exit 1
fi

# Restart SSH service
echo ""
echo "Restarting SSH service..."
systemctl restart sshd

if systemctl is-active --quiet sshd; then
    echo "✓ SSH service restarted successfully"
else
    echo "✗ SSH service failed to restart!"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$CONFIG_FILE"
    systemctl restart sshd
    echo "Backup restored."
    exit 1
fi

# Summary
echo ""
echo "========================================"
echo "✓ SSH port forwarding $ACTION_TEXT"
echo "========================================"
echo ""
echo "Backup saved at: $BACKUP_FILE"