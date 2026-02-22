#!/bin/bash
# run-mount.sh — Mount all drives defined in .install.
# Called once from the root setup.sh before any service is installed.
set -euo pipefail

source /root/scripts/.install
source /root/scripts/commons/setup-mount.sh
mount_drives
