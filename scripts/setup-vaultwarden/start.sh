#!/bin/bash

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

source $SCRIPT_DIR/commons/init-server.sh

# Launch setup
ssh -t -L 9909:localhost:8000 root@$IP '/root/scripts/setup-vaultwarden/setup.sh'
