#!/bin/bash
# restore.sh — Restore Mailcow from a backup on the configured mount.
# Mailcow containers must be running before executing this script.
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

echo "=== Restoring Mailcow from ${MAILCOW_BACKUP_LOCATION} ==="

THREADS=$(( $(nproc) > 3 ? $(nproc) - 2 : 1 )) MAILCOW_BACKUP_LOCATION="${MAILCOW_BACKUP_LOCATION}" \
    /opt/mailcow-dockerized/helper-scripts/backup_and_restore.sh restore

echo "✓ Mailcow restored"
