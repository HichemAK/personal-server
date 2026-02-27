#!/bin/bash
# restore.sh — Restore Chhoto URL's SQLite database from a backup.
# Data is OVERWRITTEN. The backup file itself is preserved.
set -euo pipefail

source ~/scripts/.install
source ~/scripts/.backup

if [ -z "${CU_BACKUP_MOUNT:-}" ]; then
    echo "Error: CU_BACKUP_MOUNT is not set in .backup"
    exit 1
fi

N="${CU_BACKUP_MOUNT}"
eval "MOUNT_POINT=\"\${MOUNT_${N}_POINT:-}\""

if [ -z "${MOUNT_POINT:-}" ]; then
    echo "Error: MOUNT_${N}_POINT is not set in .install"
    exit 1
fi

BACKUP_DIR="${MOUNT_POINT}/${CU_BACKUP_SUBDIR:-backups/chhoto}"

echo "=== Restoring Chhoto URL ==="

# List available backups, newest first
mapfile -t BACKUPS < <(ls -t "${BACKUP_DIR}"/chhoto_*.sqlite.gz.enc 2>/dev/null | xargs -I{} basename {})

if [ ${#BACKUPS[@]} -eq 0 ]; then
    echo "Error: No backup files found in ${BACKUP_DIR}."
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

echo ""
echo -n "Enter the Chhoto URL password (used to access the service online) to decrypt the backup: "
read -rs DECRYPT_PASSWORD
echo ""

# Verify the password decrypts correctly before touching the running container
if ! openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"${DECRYPT_PASSWORD}" \
        -in "${BACKUP_DIR}/${BACKUP_FILENAME}" | gunzip > /dev/null 2>&1; then
    echo "Error: Decryption failed. Wrong password or corrupted backup."
    exit 1
fi

echo "Restoring from ${BACKUP_FILENAME}..."

cd ~/scripts/setup-chhoto
docker compose stop chhoto-url
echo "✓ Stopped Chhoto URL"

# Overwrite the SQLite file inside the named volume
openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"${DECRYPT_PASSWORD}" \
        -in "${BACKUP_DIR}/${BACKUP_FILENAME}" \
    | gunzip \
    | docker run --rm -i \
        -v chhoto-db:/db \
        alpine sh -c 'cat > /db/urls.sqlite'
echo "✓ Database restored"

# Remove WAL files to prevent stale transactions being replayed on startup
docker run --rm \
    -v chhoto-db:/db \
    alpine sh -c 'rm -f /db/urls.sqlite-wal /db/urls.sqlite-shm'

# Update compose.yaml to use the restored password so the service accepts it
yq -i '.services.chhoto-url.environment.password = strenv(DECRYPT_PASSWORD)' \
    ~/scripts/setup-chhoto/compose.yaml
echo "✓ Password updated in compose.yaml"

docker compose up -d
echo "✓ Chhoto URL restarted"
