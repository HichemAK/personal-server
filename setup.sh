#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
if [ ! -f "$SCRIPT_DIR/.install" ]; then
    echo "Error: .install file not found."
    echo "Copy .install.example to .install, fill in your values, then run: chmod 600 .install"
    exit 1
fi
source "$SCRIPT_DIR/.install"

echo "=== Hetzner Server Setup ==="
echo ""

# Sync scripts and config to the remote server
bash "$SCRIPT_DIR/scripts/commons/init-server.sh"

# Mount drives once on the server before any service setup
echo "=== Mounting drives ==="
ssh root@"$SERVER_IP" '~/scripts/commons/run-mount.sh && ~/scripts/commons/swap.sh 4096 /swapfile'

# Install selected services in order
_installed=false

if [ -n "${ACTION_VAULTWARDEN:-}" ]; then
    _installed=true
    "$SCRIPT_DIR/scripts/setup-vaultwarden/start.sh"
fi

if [ -n "${ACTION_MAILCOW:-}" ]; then
    _installed=true
    "$SCRIPT_DIR/scripts/setup-mailcow/start.sh"
fi

if [ -n "${ACTION_NEXTCLOUD:-}" ]; then
    _installed=true
    "$SCRIPT_DIR/scripts/setup-nextcloud/start.sh"
fi

if [ -n "${ACTION_OMV:-}" ]; then
    _installed=true
    "$SCRIPT_DIR/scripts/setup-omv/start.sh"
fi

if [ "$_installed" = "false" ]; then
    echo "No services selected."
    echo "Set ACTION_VAULTWARDEN, ACTION_MAILCOW, ACTION_NEXTCLOUD,"
    echo "or ACTION_OMV to install, uninstall, or reinstall in .install."
fi
