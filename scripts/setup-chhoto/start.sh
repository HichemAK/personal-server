#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load configuration (SERVER_IP, ACTION_CHHOTO, etc.)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set in .install"
    exit 1
fi

case "${ACTION_CHHOTO:-}" in
    uninstall)
        echo "=== Uninstalling Chhoto URL ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-chhoto/remove.sh'
        exit 0
        ;;
    reinstall)
        echo "=== Reinstalling Chhoto URL: running remove.sh ==="
        ssh root@"$SERVER_IP" 'bash ~/scripts/setup-chhoto/remove.sh'
        ;;
    install)
        if ssh root@"$SERVER_IP" 'docker ps -a --format "{{.Names}}" | grep -q "^chhoto-url$"'; then
            echo "Chhoto URL is already installed. Skipping."
            exit 0
        fi
        ;;
    *) echo "Error: ACTION_CHHOTO must be install, uninstall, or reinstall"; exit 1 ;;
esac

# Launch setup
ssh root@"$SERVER_IP" 'bash ~/scripts/setup-chhoto/setup.sh'
