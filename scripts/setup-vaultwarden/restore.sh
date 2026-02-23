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

if [ -z "${VW_RESTORE_BACKUP_FILE:-}" ]; then
    echo "Error: VW_RESTORE_BACKUP_FILE is not set in .backup"
    exit 1
fi

# Stop VaultWarden (keep containers — they hold the bind-mount path)
cd ~/scripts
docker compose stop vaultwarden vaultwarden-backup 2>/dev/null || docker compose stop vaultwarden
echo "✓ Stopped VaultWarden"

DATA_DIR="${VAULTWARDEN_DATA_DIR:-$HOME/vw-data}"
REMOTE_NAME="VaultWardenBackup"
RCLONE_DIR="${VW_BACKUP_RCLONE_DIR:-/VaultWardenBackup}"

echo "=== Restoring VaultWarden ==="

RESTORE_TMPDIR="$(mktemp -d)"
trap "rm -rf '${RESTORE_TMPDIR}'" EXIT

if [ "${VW_RESTORE_BACKUP_FILE}" = "latest" ]; then
    echo "Fetching latest backup from '${REMOTE_NAME}:${RCLONE_DIR}'..."
    LATEST="$(docker run --rm \
        --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
        ttionya/vaultwarden-backup:latest \
        rclone lsf --order-by modtime,desc \
        "${REMOTE_NAME}:${RCLONE_DIR}" | head -1)"
    if [ -z "$LATEST" ]; then
        echo "Error: No backup files found on '${REMOTE_NAME}:${RCLONE_DIR}'."
        exit 1
    fi
    echo "Downloading ${LATEST}..."
    docker run --rm \
        --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
        --mount type=bind,source="${RESTORE_TMPDIR}",target=/restore/ \
        ttionya/vaultwarden-backup:latest \
        rclone copy "${REMOTE_NAME}:${RCLONE_DIR}/${LATEST}" /restore/
    BACKUP_FILENAME="${LATEST}"
else
    if [ ! -f "${VW_RESTORE_BACKUP_FILE}" ]; then
        echo "Error: Backup file '${VW_RESTORE_BACKUP_FILE}' not found on this host."
        exit 1
    fi
    cp "${VW_RESTORE_BACKUP_FILE}" "${RESTORE_TMPDIR}/"
    BACKUP_FILENAME="$(basename "${VW_RESTORE_BACKUP_FILE}")"
fi

# Confirm before overwriting data (unless force mode)
if [ "${VW_RESTORE_FORCE:-false}" != "true" ]; then
    echo "WARNING: This will overwrite all VaultWarden data. Type 'yes' to confirm:"
    read -r CONFIRM
    if [ "${CONFIRM}" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

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
