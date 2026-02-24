#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_NEXTCLOUD, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_NEXTCLOUD:-}" in
    uninstall)
        echo "=== Uninstalling Nextcloud ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-nextcloud/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling Nextcloud: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-nextcloud/remove.sh'
        ;;
    install)
        if ssh root@"$SERVER_IP" 'docker ps -a --format "{{.Names}}" | grep -qE "^nextcloud-aio"'; then
            echo "Nextcloud is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_NEXTCLOUD must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Activate SSH forwarding
ssh root@"$SERVER_IP" '~/scripts/commons/toggle-ssh-forwarding.sh yes'

# Launch setup
ssh -t -L 9909:localhost:8080 root@"$SERVER_IP" 'bash ~/scripts/setup-nextcloud/setup.sh'
