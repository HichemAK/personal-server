#!/bin/bash
# restore.sh — Restore VaultWarden from a backup archive.
# Data is OVERWRITTEN. The backup archive itself is preserved.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.backup

if [ -z "${VW_BACKUP_ZIP_PASSWORD:-}" ]; then
    echo "Error: VW_BACKUP_ZIP_PASSWORD is not set in .backup"
    exit 1
fi

DATA_DIR="${VAULTWARDEN_DATA_DIR:-$HOME/vw-data}"
REMOTE_NAME="VaultWardenBackup"
RCLONE_DIR="${VW_BACKUP_RCLONE_DIR:-/VaultWardenBackup}"

echo "=== Restoring VaultWarden ==="

RESTORE_TMPDIR="$(mktemp -d)"
trap "rm -rf '${RESTORE_TMPDIR}'" EXIT

# List all backups and let the user pick one
echo "Fetching available backups from '${REMOTE_NAME}:${RCLONE_DIR}'..."
mapfile -t BACKUPS < <(docker run --rm \
    --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
    ttionya/vaultwarden-backup:latest \
    rclone lsf --order-by modtime,desc \
    "${REMOTE_NAME}:${RCLONE_DIR}")

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "Error: No backup files found on '${REMOTE_NAME}:${RCLONE_DIR}'."
    exit 1
fi

echo ""
for i in "${!BACKUPS[@]}"; do
    echo "  [$((i+1))] ${BACKUPS[$i]}"
done
echo ""
echo "Select a backup to restore [1-${#BACKUPS[@]}]:"
read -r SELECTION

if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "${#BACKUPS[@]}" ]; then
    echo "Invalid selection. Aborted."
    exit 1
fi

BACKUP_FILENAME="${BACKUPS[$((SELECTION-1))]}"
echo "Downloading ${BACKUP_FILENAME}..."
docker run --rm \
    --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
    --mount type=bind,source="${RESTORE_TMPDIR}",target=/restore/ \
    ttionya/vaultwarden-backup:latest \
    rclone copy "${REMOTE_NAME}:${RCLONE_DIR}/${BACKUP_FILENAME}" /restore/

# Stop VaultWarden (keep containers — they hold the bind-mount path)
cd ~/scripts
docker compose stop vaultwarden vaultwarden-backup 2>/dev/null || docker compose stop vaultwarden
echo "✓ Stopped VaultWarden"

docker run --rm \
    --mount type=bind,source="${DATA_DIR}",target=/data/ \
    --mount type=bind,source="${RESTORE_TMPDIR}",target=/bitwarden/restore/ \
    -e DATA_DIR="/data" \
    ttionya/vaultwarden-backup:latest \
    restore --zip-file "/bitwarden/restore/${BACKUP_FILENAME}" \
            --password "${VW_BACKUP_ZIP_PASSWORD}" --force-restore
rm -f "${VAULTWARDEN_DATA_DIR}/db.sqlite3-wal" "${VAULTWARDEN_DATA_DIR}/db.sqlite3-shm"
echo "✓ VaultWarden restored"

# Restart
docker compose start vaultwarden
docker compose start vaultwarden-backup 2>/dev/null || true
echo "✓ VaultWarden restarted"
