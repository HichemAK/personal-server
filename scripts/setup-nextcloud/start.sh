#!/bin/bash

set -euo pipefail  # Exit on error, undefined variables

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/.."

source $SCRIPT_DIR/commons/init-server.sh

# Launch setup
ssh -t root@$IP '/root/scripts/setup-nextcloud/setup.sh'
