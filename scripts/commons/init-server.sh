#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

# Load .install from project root (one level above scripts/)
source "$SCRIPT_DIR/../.install"

if [ -z "${SERVER_IP:-}" ]; then
    echo "Error: SERVER_IP is not set. Please configure it in .install"
    exit 1
fi
IP="$SERVER_IP"

echo "Make sure the SSH access to your Hetzner VM is granted password-less!"
echo "Connecting to $IP..."

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" || true
ssh-keyscan -H "$IP" >> ~/.ssh/known_hosts

# Sync scripts to the remote server
rsync -avz "$SCRIPT_DIR/" root@"$IP":/root/scripts

# Sync .install separately (it lives one level above scripts/)
rsync -avz "$SCRIPT_DIR/../.install" root@"$IP":/root/scripts/.install

ssh root@"$IP" 'sudo apt-get update && /root/scripts/commons/secure-folder.sh'
