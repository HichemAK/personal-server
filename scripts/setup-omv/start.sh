#!/bin/bash

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

source $SCRIPT_DIR/commons/init-server.sh

# Activate SSH forwarding
ssh root@$IP '/root/commons/toggle-ssh-forwarding.sh yes'

# Launch setup
ssh -t -L 9909:localhost:80 root@$IP '/root/scripts/setup-omv/setup.sh'
