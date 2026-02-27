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

echo "Make sure the SSH access to your VM is granted password-less!"
echo "Connecting to $IP..."

ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$IP" || true
ssh-keyscan -H "$IP" >> ~/.ssh/known_hosts

ssh root@$IP "sudo apt update && sudo apt install rsync -y"

# Sync scripts to the remote server
rsync -avz "$SCRIPT_DIR/" root@"$IP":~/scripts

# Sync .install, .backup and .security (they live one level above scripts/)
rsync -avz "$SCRIPT_DIR/../.install" "$SCRIPT_DIR/../.backup" "$SCRIPT_DIR/../.security" root@"$IP":~/scripts/

ssh root@"$IP" 'sudo apt-get update && ~/scripts/commons/secure-folder.sh'

ssh root@"$IP" '~/scripts/commons/harden.sh'
