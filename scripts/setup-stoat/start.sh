#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_STOAT, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_STOAT:-}" in
    uninstall)
        echo "=== Uninstalling Stoat ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-stoat/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling Stoat: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-stoat/remove.sh'
        ;;
    install)
        if ssh root@"$SERVER_IP" 'docker ps -a --format "{{.Names}}" | grep -q "^stoat-database-1$"'; then
            echo "Stoat is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_STOAT must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Launch setup
ssh -t root@"$SERVER_IP" 'bash ~/scripts/setup-stoat/setup.sh'
