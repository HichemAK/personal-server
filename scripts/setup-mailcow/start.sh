#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_MAILCOW, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_MAILCOW:-}" in
    uninstall)
        echo "=== Uninstalling Mailcow ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-mailcow/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling Mailcow: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-mailcow/remove.sh'
        ;;
    install)
        if ssh root@"$SERVER_IP" '[ -d /opt/mailcow-dockerized ]'; then
            echo "Mailcow is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_MAILCOW must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Launch setup
ssh -t root@"$SERVER_IP" 'bash ~/scripts/setup-mailcow/setup.sh'
