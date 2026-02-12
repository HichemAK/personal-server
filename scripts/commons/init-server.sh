#!/bin/bash

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

echo "Make sure the SSH access to your Hetzner VM is granted password-less!"

read -p "Enter VM IP address: " IP

ssh-keygen -f '~/.ssh/known_hosts' -R "$IP" || true
ssh-keyscan -H $IP >> ~/.ssh/known_hosts

rsync -avz $SCRIPT_DIR/ root@$IP:/root/scripts

# Activate SSH forwarding
ssh root@$IP 'sudo apt-get update && /root/scripts/commons/secure-folder.sh && '

# Launch setup
ssh -t -L 9909:localhost:80 root@$IP '/root/scripts/setup-omv/setup.sh'
