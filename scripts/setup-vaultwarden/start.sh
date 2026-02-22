#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_VAULTWARDEN, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_VAULTWARDEN:-}" in
    uninstall)
        echo "=== Uninstalling VaultWarden ==="
        ssh root@"$SERVER_IP" 'bash /root/scripts/setup-vaultwarden/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling VaultWarden: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash /root/scripts/setup-vaultwarden/remove.sh'
        ;;
    install) ;;
    *) echo "Error: ACTION_VAULTWARDEN must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Launch setup
ssh -t root@"$SERVER_IP" 'bash /root/scripts/setup-vaultwarden/setup.sh'
