#!/bin/bash

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Make sure the SSH access to your Hetzner VM is granted password-less!"

read -p "Enter VM IP address: " IP

ssh-keygen -f '/home/rareseven/.ssh/known_hosts' -R "$IP" || true
ssh-keyscan -H $IP >> ~/.ssh/known_hosts

rsync -avz $SCRIPT_DIR/scripts/ root@$IP:/root/server

# Activate SSH forwarding
ssh root@$IP '/root/server/secure-folder.sh && /root/server/toggle-ssh-forwarding.sh yes'

# Launch setup
ssh -t -L 9909:localhost:80 root@$IP '/root/server/setup.sh'
