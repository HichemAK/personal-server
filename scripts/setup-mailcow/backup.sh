#!/bin/bash
# backup.sh — Back up Mailcow to the configured mount.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.backup

if [ -z "${MC_BACKUP_MOUNT:-}" ]; then
    echo "Error: MC_BACKUP_MOUNT is not set in .backup"
    exit 1
fi

N="${MC_BACKUP_MOUNT}"
eval "MOUNT_POINT=\"\${MOUNT_${N}_POINT:-}\""

if [ -z "${MOUNT_POINT:-}" ]; then
    echo "Error: MOUNT_${N}_POINT is not set in .install"
    exit 1
fi

MAILCOW_BACKUP_LOCATION="${MOUNT_POINT}/${MC_BACKUP_SUBDIR:-backups/mailcow}"
mkdir -p "${MAILCOW_BACKUP_LOCATION}"

echo "=== Backing up Mailcow to ${MAILCOW_BACKUP_LOCATION} ==="

cd /opt/mailcow-dockerized
MAILCOW_BACKUP_LOCATION="${MAILCOW_BACKUP_LOCATION}" \
    ./helper-scripts/backup_and_restore.sh backup all \
    --delete-days "${MC_BACKUP_KEEP_DAYS:-30}"

echo "✓ Mailcow backup complete"
