#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_OMV, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_OMV:-}" in
    uninstall)
        echo "=== Uninstalling OpenMediaVault ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-omv/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling OpenMediaVault: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-omv/remove.sh'
        ;;
    install)
        if ssh root@"$SERVER_IP" 'dpkg -l openmediavault &>/dev/null'; then
            echo "OpenMediaVault is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_OMV must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Activate SSH forwarding
ssh root@"$SERVER_IP" '~/scripts/commons/toggle-ssh-forwarding.sh yes'

# Launch setup
ssh -t -L 9909:localhost:80 root@"$SERVER_IP" 'bash ~/scripts/setup-omv/setup.sh'
