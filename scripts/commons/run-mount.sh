#!/bin/bash
# run-mount.sh — Mount all drives defined in .install.
# Called once from the root setup.sh before any service is installed.
set -euo pipefail

source $HOME/scripts/.install
source $HOME/scripts/commons/setup-mount.sh
mount_drives
